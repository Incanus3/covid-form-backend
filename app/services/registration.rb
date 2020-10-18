require 'dry/monads'
require 'dry/monads/do'

require 'lib/utils'
require 'app/dependencies'

module CovidForm
  module Services
    class Registration
      include Import[:config, :db, :mail_sender]
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:perform)

      class ClientAlreadyRegisteredForDate < Failure
        def initialize(client:, date:)
          super({ client: client, date: date })
        end
      end

      class DailyRegistrationLimitReached < Failure
        def initialize(date)
          super({ date: date })
        end
      end

      class SlotRegistrationLimitReached < Failure
        def initialize(date, slot)
          super({ date: date, slot: slot })
        end
      end

      class NonexistentTimeSlot < Failure
        def initialize(time_slot_id)
          super({ id: time_slot_id })
        end
      end

      def self.perform(data)
        new(data: data).perform
      end

      def initialize(config:, db:, mail_sender:, data:)
        @config      = config
        @db          = db
        @mail_sender = mail_sender

        @client_data = data.slice(:first_name, :last_name, :municipality, :zip_code,
                                  :email, :phone_number, :insurance_number, :insurance_company)
        @registration_data = data.slice(:requestor_type, :exam_type, :exam_date, :time_slot_id)

        @all_time_slots = db.time_slots.all
        @time_slot      = all_time_slots.find { _1.id == registration_data[:time_slot_id] }
      end

      def perform
        db.clients.transaction do
          client       = yield create_or_update_client
          registration = yield create_registration(client)

          yield send_mail(client)

          Success.new({ client: client, registration: registration })
        end
      end

      private

      attr_reader(:config, :db, :mail_sender, :client_data,
                  :registration_data, :all_time_slots, :time_slot)

      def create_or_update_client
        existing = db.clients.lock_by_insurance_number(client_data[:insurance_number])

        client =
          if existing.exist?
            without_ins_num = Utils::Hash.reject_keys(client_data, [:insurance_number])

            existing.command(:update).call(without_ins_num)
          else
            db.clients.create(client_data)
          end

        Success.new(client)
      end

      def create_registration(client)
        exam_date = registration_data[:exam_date]

        return NonexistentTimeSlot.new(registration_data[:time_slot_id]) unless time_slot

        existing_count_for_day, existing_count_for_slot = existing_counts_for(exam_date, time_slot)
        daily_limit, slot_limit                         = limits_for(exam_date, time_slot)

        return DailyRegistrationLimitReached.new(exam_date) if existing_count_for_day >= daily_limit

        if existing_count_for_slot >= slot_limit
          return SlotRegistrationLimitReached.new(exam_date, time_slot)
        end

        begin
          Success.new(db.registrations.create_for_client(registration_data, client))
        rescue ROM::SQL::UniqueConstraintError # FIXME: this is an abstraciton leak
          ClientAlreadyRegisteredForDate.new(client: client, date: registration_data[:exam_date])
        end
      end

      def send_mail(client)
        mail = mail_sender.deliver {
          to      client.email
          subject I18n.t('registration.success_email_subject')

          text_part do
            content_type 'text/plain; charset=UTF-8'
            body         I18n.t('registration.success_email_body')
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body         "<p>#{I18n.t('registration.success_email_body')}</p>"
          end
        }

        Success.new(mail)
      end


      def existing_counts_for(date, time_slot)
        for_day  = db.registrations.count_for_date(date)
        for_slot = db.registrations.count_for_date_and_slot(date, time_slot)

        [for_day, for_slot]
      end

      def limits_for(date, time_slot)
        daily_registration_limit = registration_limit_for_date(date)
        slot_registration_limit  = registration_limit_for_slot(daily_registration_limit, time_slot)

        [daily_registration_limit, slot_registration_limit]
      end

      def registration_limit_for_date(date)
        daily_override = db.daily_overrides.for_date(date)

        daily_override&.registration_limit || config[:daily_registration_limit]
      end

      # FIXME: we should be able to get this from db directly
      def registration_limit_for_slot(daily_limit, slot)
        coeff_sum = all_time_slots.map(&:limit_coefficient).sum

        ((daily_limit / coeff_sum) * slot.limit_coefficient).ceil
      end
    end
  end
end

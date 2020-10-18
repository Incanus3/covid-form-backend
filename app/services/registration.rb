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

      class NonexistentTimeSlot < Failure
        def initialize(time_slot_id)
          super({ id: time_slot_id })
        end
      end

      attr_private_initialize %i[config db mail_sender data]

      def self.perform(data)
        new(data: data).perform
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

      def create_or_update_client
        client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                      :email, :phone_number, :insurance_number, :insurance_company)

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
        registration_data = self.data.slice(:requestor_type, :exam_type, :exam_date, :time_slot_id)

        exam_date                   = registration_data[:exam_date]
        existing_registration_count = db.registrations.count_for_date(exam_date)
        daily_registration_limit    = registration_limit_for(exam_date)

        if existing_registration_count >= daily_registration_limit
          return DailyRegistrationLimitReached.new(exam_date)
        end

        begin
          Success.new(db.registrations.create_for_client(registration_data, client))
        rescue ROM::SQL::UniqueConstraintError # FIXME: this is an abstraciton leak
          ClientAlreadyRegisteredForDate.new(client: client, date: registration_data[:exam_date])
        rescue ROM::SQL::ForeignKeyConstraintError # FIXME: this is an abstraciton leak
          NonexistentTimeSlot.new(registration_data[:time_slot_id])
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

      def registration_limit_for(date)
        daily_override = db.daily_overrides.for_date(date)

        daily_override&.registration_limit || config[:daily_registration_limit]
      end
    end
  end
end

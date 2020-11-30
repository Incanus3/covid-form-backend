require 'dry/monads'
require 'dry/monads/do'

require 'lib/utils'
require 'app/dependencies'
require 'app/mailers/registration_confirmation'
require_relative 'registration_limits'

module CovidForm
  module Services
    class Registration
      include Import[:config, :db]
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

      attr_private_initialize [:config, :db, :client_data, :exam_data] do
        @all_time_slots = db.time_slots.all_with_time_ranges
        @time_slot      = all_time_slots.find { _1.id == exam_data[:time_slot_id] }
        @limits         = RegistrationLimits.new(all_time_slots)
      end

      attr_private :all_time_slots, :time_slot, :limits

      def perform
        db.clients.transaction do
          client       = yield create_or_update_client
          registration = yield create_registration_for(client)

          yield send_mail_to(client)

          Success.new({ client: client, registration: registration })
        end
      end

      private

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

      def create_registration_for(client)
        exam_date = exam_data[:exam_date]

        return NonexistentTimeSlot.new(exam_data[:time_slot_id]) unless time_slot

        existing_count_for_day, existing_count_for_slot = existing_counts_for(exam_date, time_slot)
        daily_limit, slot_limit                         = limits.limits_for(exam_date, time_slot)

        return DailyRegistrationLimitReached.new(exam_date) if existing_count_for_day >= daily_limit

        if existing_count_for_slot >= slot_limit
          return SlotRegistrationLimitReached.new(exam_date, time_slot)
        end

        begin
          Success.new(db.registrations.create_for_client(exam_data, client))
        rescue ROM::SQL::UniqueConstraintError # FIXME: this is an abstraciton leak
          ClientAlreadyRegisteredForDate.new(client: client, date: exam_data[:exam_date])
        end
      end

      def send_mail_to(client)
        mailer = Mailers::RegistrationConfirmation.new(client:     client,
                                                       exam_type:  exam_data[:exam_type],
                                                       exam_date:  exam_data[:exam_date],
                                                       time_range: time_slot.time_range)

        Success.new(mailer.send)
      end


      def existing_counts_for(date, time_slot)
        for_day  = db.registrations.count_for_date(date)
        for_slot = db.registrations.count_for_date_and_slot(date, time_slot)

        [for_day, for_slot]
      end
    end
  end
end

require 'dry/monads'
require 'dry/monads/do'

require 'lib/utils'
require 'app/dependencies'
require 'app/mailers/registration_confirmation'
require_relative 'registration_limits'

module CovidForm
  module Services
    class Capacity
      include Import[:config, :db]
      include Dry::Monads[:result]

      attr_private_initialize [:config, :db]

      def full_dates_between(start_date:, end_date:)
        dates = db.registrations
          .dates_with_full_capacity(start_date, end_date,
                                    global_registration_limit: config[:daily_registration_limit])

        Success.new(dates: dates)
      end

      def available_time_slots_for(_date, exam_type_id)
        # time_slots = db.time_slots.available_for_date_with_time_ranges(date)
        # p db.registrations.counts_for_date(date)
        # pp @limits_service.slot_limits_for(date)

        db.time_slots.for_exam_type_with_time_ranges(exam_type_id, remove_leading_zeros: true)
      end

      def daily_capacities_for_report(exam_type_id, start_date, end_date)
        db.registrations.daily_capacities_for(
          global_registration_limit: config[:daily_registration_limit],
          exam_type_id:              exam_type_id,
          start_date:                start_date,
          end_date:                  end_date,
        )
      end

      # private

      # def limits_service
      #   @_limits_service ||= RegistrationLimits.new(all_time_slots)
      # end

      # def all_time_slots
      #   @_all_time_slots ||= db.time_slots.all_with_time_ranges
      # end
    end
  end
end

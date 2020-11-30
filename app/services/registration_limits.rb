require 'app/dependencies'

module CovidForm
  module Services
    class RegistrationLimits
      include Import[:config, :db]

      attr_private_initialize :all_time_slots, [:config, :db]

      def limits_for(date, time_slot)
        daily_registration_limit = limit_for_date(date)
        slot_registration_limit  = limit_for_slot(daily_registration_limit, time_slot)

        [daily_registration_limit, slot_registration_limit]
      end

      # def slot_limits_for(date)
      #   daily_registration_limit = limit_for_date(date)

      #   limits_for_slots(daily_registration_limit)
      # end

      def limit_for_date(date)
        daily_override = db.daily_overrides.for_date(date)

        daily_override&.registration_limit || config[:daily_registration_limit]
      end

      private

      # def limits_for_slots(daily_limit)
      #   all_time_slots
      #     .map { |time_slot| [time_slot, limit_for_slot(daily_limit, time_slot)] }.to_h
      # end

      # FIXME: we should be able to get this from db directly
      def limit_for_slot(daily_limit, slot)
        coeff_sum = all_time_slots.sum(&:limit_coefficient)

        ((Float(daily_limit) / coeff_sum) * slot.limit_coefficient).ceil
      end
    end
  end
end

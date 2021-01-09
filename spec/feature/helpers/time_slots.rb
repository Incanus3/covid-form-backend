require 'lib/utils'

module CovidForm
  module TestHelpers
    module TimeSlots
      def populate_time_slots # rubocop:disable Metrics/MethodLength
        db.time_slots.create_many([
          {
            name:              'morning 1',
            start_time:        Utils::Time.today_at(8,  0),
            end_time:          Utils::Time.today_at(10, 0),
            limit_coefficient: 7,
          },
          {
            name:              'morning 2',
            start_time:        Utils::Time.today_at(10, 0),
            end_time:          Utils::Time.today_at(12, 0),
            limit_coefficient: 7,
          },
          {
            name:              'afternoon 1',
            start_time:        Utils::Time.today_at(13, 0),
            end_time:          Utils::Time.today_at(15, 0),
            limit_coefficient: 5,
          },
          {
            name:              'afternoon 2',
            start_time:        Utils::Time.today_at(15, 0),
            end_time:          Utils::Time.today_at(17, 0),
            limit_coefficient: 5,
          },
        ])
      end

      def morning_slots
        time_slots_where_name_ilike('morning%')
      end

      def afternoon_slots
        time_slots_where_name_ilike('afternoon%')
      end

      def first_and_last_slot
        time_slots_with_name(['morning 1', 'afternoon 2'])
      end

      def time_slots_with_name(name)
        db.time_slots.root.where(name: name)
      end

      def time_slots_where_name_ilike(pattern)
        db.time_slots.root.where { name.ilike(pattern) }
      end

      def formatted_time_range(time_slot, remove_leading_zeros: true)
        format = ->(time) { Utils::Time.format(time, remove_leading_zeros: remove_leading_zeros) }

        "#{format.call(time_slot.start_time)}-#{format.call(time_slot.end_time)}"
      end
    end
  end
end

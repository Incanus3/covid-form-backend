require 'lib/utils'

module CovidForm
  module TestHelpers
    module Generic
      # rubocop:disable Layout/LineLength
      def populate_exam_types
        db.exam_types.create_many([
          { id: 'pcr',   description: 'PCR vyšetření (výtěr z nosu a následné laboratorní zpracování)' },
          { id: 'rapid', description: 'RAPID test (orientační test z kapky krve)'                      },
          { id: 'ag',    description: 'Antigen test (výtěr z nosu a okamžitý orientační test)'         },
        ])
      end
      # rubocop:enable Layout/LineLength

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

      def populate_time_slot_exam_types
        db.time_slot_exam_types.create_many(
          morning_slots.pluck(      :id).map { |id| { time_slot_id: id, exam_type: 'pcr'   } } +
          afternoon_slots.pluck(    :id).map { |id| { time_slot_id: id, exam_type: 'rapid' } } +
          first_and_last_slot.pluck(:id).map { |id| { time_slot_id: id, exam_type: 'ag'    } },
        )
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

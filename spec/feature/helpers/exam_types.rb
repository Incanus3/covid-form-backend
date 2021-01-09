module CovidForm
  module TestHelpers
    module ExamTypes
      # rubocop:disable Layout/LineLength
      def populate_exam_types
        db.exam_types.create_many([
          { id: 'pcr',   description: 'PCR vyšetření (výtěr z nosu a následné laboratorní zpracování)' },
          { id: 'rapid', description: 'RAPID test (orientační test z kapky krve)'                      },
          { id: 'ag',    description: 'Antigen test (výtěr z nosu a okamžitý orientační test)'         },
        ])
      end
      # rubocop:enable Layout/LineLength

      # this expects TestHelpers::TimeSlots to be included as well
      def populate_time_slot_exam_types
        db.time_slot_exam_types.create_many(
          morning_slots.pluck(      :id).map { |id| { time_slot_id: id, exam_type: 'pcr'   } } +
          afternoon_slots.pluck(    :id).map { |id| { time_slot_id: id, exam_type: 'rapid' } } +
          first_and_last_slot.pluck(:id).map { |id| { time_slot_id: id, exam_type: 'ag'    } },
        )
      end
    end
  end
end

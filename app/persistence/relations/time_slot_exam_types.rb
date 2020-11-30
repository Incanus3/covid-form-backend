require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class TimeSlotExamTypes < Utils::Persistence::Relation
        schema(:time_slot_exam_types) do
          attribute :time_slot_id, Types::ForeignKey(:time_slots)
          attribute :exam_type,    Types::ForeignKey(:exam_types)

          associations do
            belongs_to :exam_type
            belongs_to :time_slot
          end
        end
      end
    end
  end
end

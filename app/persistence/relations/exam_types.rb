require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class ExamTypes < Utils::Persistence::Relation
        schema(:exam_types) do
          attribute :id,          Types::String
          attribute :description, Types::String

          primary_key :id

          associations do
            has_many :registrations
            has_many :time_slot_exam_types
            has_many :time_slots, through: :time_slot_exam_types
          end
        end
      end
    end
  end
end

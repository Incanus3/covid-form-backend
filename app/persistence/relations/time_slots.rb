require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class TimeSlots < Utils::Persistence::Relation
        schema(:time_slots) do
          attribute :id,                Types::Integer
          attribute :name,              Types::String
          attribute :start_time,        Types::Time, only_time: true
          attribute :end_time,          Types::Time, only_time: true
          attribute :limit_coefficient, Types::Integer

          primary_key :id

          associations do
            has_many :registrations
            has_many :time_slot_exam_types
            has_many :exam_types, through: :time_slot_exam_types
          end
        end

        def for_exam_type(exam_type)
          join(:exam_types).where(exam_types[:id] => exam_type)
        end

        def with_time_range(remove_leading_zeros: false)
          time_format = "#{remove_leading_zeros ? 'FM' : ''}HH24:MI"

          select_append {
            string.concat(
              string.to_char(start_time, time_format), '-', string.to_char(end_time, time_format)
            ).as(:time_range)
          }
        end
      end
    end
  end
end

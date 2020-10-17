require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class TimeSlots < Utils::Persistence::Relation
        schema(:time_slots) do
          attribute :id,         Types::Integer
          attribute :name,       Types::String
          attribute :start_time, Types::Time, only_time: true
          attribute :end_time,   Types::Time, only_time: true

          primary_key :id

          associations do
            has_many :registrations
          end
        end
      end
    end
  end
end

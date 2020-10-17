require 'lib/persistence/repository'

module CovidForm
  module Persistence
    module Repositories
      class TimeSlots < Utils::Persistence::Repository[:time_slots]
        def ids
          time_slots.pluck(:id).to_a
        end
      end
    end
  end
end

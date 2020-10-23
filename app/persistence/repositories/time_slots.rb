require 'lib/persistence/repository'

module CovidForm
  module Persistence
    module Repositories
      class TimeSlots < Utils::Persistence::Repository[:time_slots]
        def ids
          time_slots.pluck(:id).to_a
        end

        def all_with_time_ranges(remove_leading_zeros: false)
          time_slots.with_time_range(remove_leading_zeros: remove_leading_zeros).to_a
        end
      end
    end
  end
end

require 'app/dependencies'

module CovidForm
  module Web
    module CRUD
      class TimeSlots
        include Import[:db]

        static_facade :all_with_time_ranges, [:db]

        def all_with_time_ranges
          db.time_slots.all_with_time_ranges
        end
      end
    end
  end
end

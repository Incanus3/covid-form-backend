require 'app/dependencies'

module CovidForm
  module Web
    module CRUD
      class TimeSlots
        include Import[:db]

        attr_private_initialize [:db]

        def all_with_time_ranges
          db.time_slots.all_with_time_ranges
        end
      end
    end
  end
end

require 'app/dependencies'

module CovidForm
  module Web
    module CRUD
      class TimeSlots
        include Import[:db]

        static_facade :all, [:db]

        def all
          db.time_slots.all
        end
      end
    end
  end
end

module CovidForm
  module Persistence
    module DatasetModules
      module Clients
        def lock_by_insurance_number(number)
          where(insurance_number: number).for_update
        end
      end
    end
  end
end

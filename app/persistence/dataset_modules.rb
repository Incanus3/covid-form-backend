require 'lib/persistence/dataset_module'

module CovidForm
  module Persistence
    module DatasetModules
      module Clients
        include Utils::Persistence::DatasetModule

        def lock_by_insurance_number(number)
          where(insurance_number: number).for_update
        end
      end

      module Registrations
        include Utils::Persistence::DatasetModule
      end
    end
  end
end

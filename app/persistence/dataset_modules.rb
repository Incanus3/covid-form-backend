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

        COLUMNS_FOR_EXPORT = (
          %w[registered_at requestor_type exam_type exam_date last_name first_name] +
          %w[insurance_number insurance_company zip_code municipality phone_number email]
        ).freeze

        def with_clients
          join(:clients, id: :client_id)
        end

        def for_export
          with_clients.select(COLUMNS_FOR_EXPORT)
        end
      end
    end
  end
end

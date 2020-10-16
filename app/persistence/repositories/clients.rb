require 'lib/persistence/repository'

module CovidForm
  module Persistence
    module Repositories
      class Clients < Utils::Persistence::Repository[:clients]
        def find_by_insurance_number(number)
          clients.by_insurance_number(number).one!
        end

        def lock_by_insurance_number(number)
          clients.by_insurance_number(number).lock
        end
      end
    end
  end
end

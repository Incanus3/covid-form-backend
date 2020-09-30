require 'sequel/model'

module CovidForm
  module Persistence
    # when this is defined, Sequel.connect must have already been called
    class Clients < Sequel::Model
      dataset_module do
        def lock_by_insurance_number(number)
          where(insurance_number: number).for_update
        end
      end
    end
  end
end

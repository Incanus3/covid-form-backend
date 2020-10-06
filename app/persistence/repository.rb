require 'lib/persistence/repository'
require 'app/entities'
require_relative 'dataset_modules'

module CovidForm
  module Persistence
    class Repository < Utils::Persistence::Repository
      attr_private_initialize [:database]

      register_relation(:clients,
                        constructor:    Entities::Client,
                        dataset_module: DatasetModules::Clients)

      register_relation(:registrations,
                        constructor:    Entities::Registration,
                        dataset_module: DatasetModules::Registrations)
    end
  end
end

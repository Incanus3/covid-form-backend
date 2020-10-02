require 'lib/persistence/repository'
require 'app/entities'
require_relative 'dataset_modules'

module CovidForm
  module Persistence
    class Repository < Utils::Persistence::Repository
      include Import[:db]

      def clients
        get_relation(:clients, constructor: Client, dataset_module: DatasetModules::Clients)
      end
    end
  end
end

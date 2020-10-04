require 'attr_extras'
require 'base_helper'
require 'lib/persistence/database'
require 'lib/persistence/repository'
require 'lib/persistence/dataset_module'

module PersistenceTests
  module Entities
    Client = Struct.new(:first_name, :last_name, :email, :phone_number, :id, keyword_init: true)
  end

  module DatasetModules
    module Clients
      include Utils::Persistence::DatasetModule

      def by_email(email)
        where(email: email)
      end
    end
  end

  class Repository < Utils::Persistence::Repository
    attr_private_initialize [:db]

    register_relation(:clients,
                      constructor:    Entities::Client,
                      dataset_module: DatasetModules::Clients)
  end
end

RSpec.describe Utils::Persistence::Repository do
  it 'works' do
    db         = Utils::Persistence::Database.new(adapter: 'sqlite', database: ':memory:')
    repository = PersistenceTests::Repository.new(db: db)

    # TODO: we will have to create tables somehow

    p repository
  end
end

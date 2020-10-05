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
    attr_private_initialize [:database]

    register_relation(:clients,
                      constructor:    Entities::Client,
                      dataset_module: DatasetModules::Clients)
  end
end

RSpec.describe Utils::Persistence::Repository do
  let(:database)   { Utils::Persistence::Database.new(adapter: 'sqlite', database: ':memory:') }
  let(:repository) { PersistenceTests::Repository.new(database: database)                      }

  before do
    database.sequel_db.create_table(:clients) do
      primary_key :id

      column :first_name,   String, null: false
      column :last_name,    String, null: false
      column :email,        String, null: false
      column :phone_number, String
    end
  end

  after do
    database.sequel_db.drop_table(:clients)
  end

  it 'works' do
    repository.clients.insert(first_name: 'Testy', last_name: 'Testson', email: 'testy@testson.org')
    repository.clients.insert(first_name: 'Your',  last_name: 'Mama',    email: 'your@mama.codes')

    client = repository.clients.by_email('your@mama.codes').first!

    expect(client).to be_a PersistenceTests::Entities::Client
    expect(client.last_name).to eq 'Mama'
  end
end

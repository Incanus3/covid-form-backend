require 'base_helper'
require 'lib/transformations'
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

    register_relation(:clients)
    register_relation(:clients_with_entity_constructor,
                      table_name:  'clients',
                      constructor: Entities::Client)
    register_relation(:clients_with_callable_constructor,
                      table_name:  'clients',
                      constructor: Utils::Transformations[:stringify_keys])
    register_relation(:clients_with_custom_dm,
                      table_name:     'clients',
                      dataset_module: DatasetModules::Clients)
    register_relation(:clients_with_invalid_constructor,
                      table_name:  'clients',
                      constructor: 'bad')

    register_relation(:nonexistent)
  end
end

RSpec.describe Utils::Persistence::Repository do
  let(:database)   { Utils::Persistence::Database.new(adapter: 'sqlite', database: ':memory:') }
  let(:repository) { PersistenceTests::Repository.new(database: database)                      }

  before do
    database.create_table(:clients) do
      primary_key :id

      column :first_name,   String, null: false
      column :last_name,    String, null: false
      column :email,        String, null: false
      column :phone_number, String
    end

    repository.clients.insert(first_name: 'Testy', last_name: 'Testson', email: 'testy@testson.org')
    repository.clients.insert(first_name: 'Your',  last_name: 'Mama',    email: 'your@mama.codes')
  end

  after do
    database.disconnect
  end

  it 'works' do
    expect(repository.clients.count).to eq 2
    expect(repository.clients.map(:last_name)).to include 'Mama'
  end

  it 'supports custom dataset modules' do
    expect {
      repository.clients.by_email
    }.to raise_exception NoMethodError

    client = repository.clients_with_custom_dm.by_email('your@mama.codes').first!

    expect(client[:last_name]).to eq 'Mama'
  end

  it 'supports custom constructors' do
    expect(repository.clients.first).to be_a Hash
    expect(repository.clients.first.keys).to all(be_a Symbol)
    expect(repository.clients_with_callable_constructor.first.keys).to all(be_a String)
    expect(repository.clients_with_entity_constructor.first)
      .to be_a PersistenceTests::Entities::Client
    expect {
      repository.clients_with_invalid_constructor.all
    }.to raise_exception Utils::Persistence::InvalidConstructor
  end

  it 'handles nonexistent table' do
    expect {
      repository.nonexistent.all
    }.to raise_exception Utils::Persistence::MissingTable
  end

  it 'provides relation with meaningful string representations' do
    expect(repository.clients.name   ).to eq 'Clients'
    expect(repository.clients.to_s   ).to eq 'Clients'
    expect(repository.clients.inspect).to eq '#<Relation clients>'
  end
end

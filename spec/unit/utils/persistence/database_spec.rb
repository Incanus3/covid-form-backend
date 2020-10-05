require 'base_helper'
require 'lib/persistence/database'

RSpec.describe Utils::Persistence::Database do
  let(:database) { described_class.new(adapter: 'sqlite', database: ':memory:') }

  after do
    database.disconnect
  end

  describe 'connecting' do
    it 'can be connected explicitly' do
      expect(database.connected?).to be false

      database.connect

      expect(database.connected?).to be true
    end

    it 'can be connected for block execution' do
      expect(database.connected?).to be false

      database.connect do |transient_db|
        expect(transient_db.connected?).to be true
      end

      expect(database.connected?).to be false
    end

    it 'will connect automatically on first access' do
      expect(database.connected?).to be false

      database[:clients]

      expect(database.connected?).to be true
    end

    it 'will retain Sequel::Database instance on multiple #connect calls' do
      database.connect
      sequel_db = database.sequel_db
      database.connect

      expect(database.sequel_db).to be sequel_db

      database.connect do |db|
        expect(db.sequel_db).to be sequel_db
      end
    end
  end

  describe '#backend_type' do
    it 'works' do
      expect(database.backend_type).to eq :sqlite
    end
  end
end

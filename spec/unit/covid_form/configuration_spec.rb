require 'base_helper'
require 'helpers/database'
require 'app/configuration'
require 'app/dependencies'

RSpec.describe CovidForm::Configuration do
  CovidForm::Dependencies.start(:persistence)

  include CovidForm::Import[:db]

  before do
    allow_any_instance_of(described_class)
      .to receive(:default_general_options)
      .and_return({
        daily_registration_limit:     10,
        enable_registration_deadline: true,
      })
  end

  describe 'access' do
    context 'when overridden' do
      subject(:configuration) { described_class.new(:test, db, daily_registration_limit: 5) }

      before do
        db.settings.create(key: 'daily_registration_limit', value: 15)
      end

      it 'the override always wins' do
        expect(configuration.daily_registration_limit  ).to eq 5
        expect(configuration[:daily_registration_limit]).to eq 5
      end
    end

    context 'when not overridden' do
      subject(:configuration) { described_class.new(:test, db) }

      context 'when present in settings table' do
        before do
          db.settings.create(key: 'daily_registration_limit', value: 15)
        end

        it 'returns the value from settings table' do
          expect(configuration.daily_registration_limit  ).to eq 15
          expect(configuration[:daily_registration_limit]).to eq 15
        end
      end

      context 'when not present in settings table' do
        context 'when default exists' do
          it 'returns the default' do
            expect(configuration.daily_registration_limit   ).to eq 10
            expect(configuration['daily_registration_limit']).to eq 10
          end
        end

        context "when default doesn't exist" do
          it 'returns nil' do
            expect(configuration.nonexistent_key  ).to be nil
            expect(configuration[:nonexistent_key]).to be nil
          end
        end
      end
    end
  end

  describe '#to_h' do
    before do
      db.settings.create_many([
        { key: 'daily_registration_limit',        value: 15   },
        { key: 'allow_registration_for_weekends', value: true },
      ])
    end

    subject(:configuration) {
      described_class.new(:test, db, allow_registration_for_weekends: false)
    }

    it 'returns values from all three sources' do
      expect(configuration.to_h[:allow_registration_for_weekends]).to be false # override
      expect(configuration.to_h[:daily_registration_limit       ]).to eq 15    # db
      expect(configuration.to_h[:enable_registration_deadline   ]).to be true  # default
    end
  end
end

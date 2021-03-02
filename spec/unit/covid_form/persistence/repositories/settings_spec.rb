require 'base_helper'
require 'helpers/database'
require 'app/dependencies'

RSpec.describe 'CovidForm::Persistence::Repositories::Settings' do
  CovidForm::Dependencies.start(:persistence)

  include CovidForm::Import[:db]

  before do
    db.settings.create_many([
      { key: 'daily_registration_limit',        value: 15   },
      { key: 'allow_registration_for_weekends', value: true },
    ])
  end

  describe '#value_for' do
    context 'when the option is present' do
      it 'returns it' do
        expect(db.settings.value_for('daily_registration_limit')).to eq 15
      end
    end

    context "when the option isn't present" do
      it 'returns nil' do
        expect(db.settings.value_for('nonexistent_key')).to be nil
      end
    end
  end

  describe '#value_for!' do
    context 'when the option is present' do
      it 'returns it' do
        expect(db.settings.value_for!('daily_registration_limit')).to eq 15
      end
    end

    context "when the option isn't present" do
      it 'returns raises NotFound exception' do
        expect do
          db.settings.value_for!('nonexistent_key')
        end.to raise_exception db.settings.class::NotFound
      end
    end
  end
end

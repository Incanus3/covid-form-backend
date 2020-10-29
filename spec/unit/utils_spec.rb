require 'base_helper'
require 'lib/utils'

RSpec.describe 'Utils::Date' do
  subject(:mail_sender) { described_class.new(env: :test, default_from: 'default@test.cz') }

  describe '#days_in_month' do
    it 'works worn normal months' do
      expect(Utils::Date.days_in_month(month: 1 )).to eq 31
      expect(Utils::Date.days_in_month(month: 4 )).to eq 30
      expect(Utils::Date.days_in_month(month: 9 )).to eq 30
      expect(Utils::Date.days_in_month(month: 12)).to eq 31
    end

    it 'works worn February' do
      expect(Utils::Date.days_in_month(month: 2, year: 2001)).to eq 28
      expect(Utils::Date.days_in_month(month: 2, year: 2004)).to eq 29
      expect(Utils::Date.days_in_month(month: 2, year: 2100)).to eq 28
      expect(Utils::Date.days_in_month(month: 2, year: 2000)).to eq 29
    end
  end
end

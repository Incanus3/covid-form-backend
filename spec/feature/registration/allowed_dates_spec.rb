require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'GET /registration/allowed_dates route' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration

  before do
    mock_config_with(
      week_starts_on:              6, # saturday
      open_registration_in_weeks:  1,
      close_registration_in_weeks: 2,
    )
  end

  it 'works in the middle of the week' do
    Timecop.freeze(Date.new(2021, 3, 3)) do # wednesday
      get '/registration/allowed_dates'

      expect(last_response).to be_ok
      expect(last_response.symbolized_json).to eq({
        status:     'OK',
        start_date: '2021-03-06',
        end_date:   '2021-03-19',
      })
    end
  end

  it 'works at the end of the week' do
    Timecop.freeze(Date.new(2021, 3, 5)) do # friday
      get '/registration/allowed_dates'

      expect(last_response).to be_ok
      expect(last_response.symbolized_json).to eq({
        status:     'OK',
        start_date: '2021-03-06',
        end_date:   '2021-03-19',
      })
    end
  end

  it 'works at the beginning of the week' do
    Timecop.freeze(Date.new(2021, 3, 6)) do # saturday
      get '/registration/allowed_dates'

      expect(last_response).to be_ok
      expect(last_response.symbolized_json).to eq({
        status:     'OK',
        start_date: '2021-03-13',
        end_date:   '2021-03-26',
      })
    end
  end
end

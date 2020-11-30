require 'spec_helper'
require 'spec/feature/registration/helpers'

RSpec.feature 'GET /capacity/full_dates route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:config, :db]

  let(:full_date)                { Date.today + 1 }
  let(:closed_date)              { Date.today + 2 }
  let(:daily_registration_limit) { 10             }

  before do
    populate_exam_types
    populate_time_slots

    mock_config_with(daily_registration_limit:        daily_registration_limit,
                     allow_registration_for_weekends: false)

    db.daily_overrides.create(date: closed_date, registration_limit: 0)

    create_many_clients_with_registrations(daily_registration_limit,
                                           exam_overrides: { exam_date: full_date })
  end

  context 'with valid params' do
    it 'returns dates with capacity limit reached' do
      get '/capacity/full_dates', start_date: Date.today, end_date: Date.today + 10

      expect(last_response).to be_ok
      expect(last_response.symbolized_json).to match({
        status: 'OK',
        dates:  a_collection_including(full_date.iso8601, closed_date.iso8601),
      })
    end
  end

  context 'with invalid params' do
    it 'returns a proper validation error' do
      get '/capacity/full_dates', start_date: Date.today, end_date: Date.today - 10

      expect(last_response).to be_unprocessable
      expect(last_response.symbolized_json).to match({
        status: 'ERROR',
        error:  a_collection_including('end_date must be after start_date'),
      })
    end
  end
end

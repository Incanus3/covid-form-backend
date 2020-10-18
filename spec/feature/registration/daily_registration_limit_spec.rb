require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:db]

  let(:exam_date)                { Faker::Date.forward(days: 60) }
  let(:daily_registration_limit) { 5                             }
  let(:configuration)            {
    {
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
    }
  }

  before do
    populate_time_slots

    mock_config_with(configuration)

    create_many_clients_with_registrations(daily_registration_limit,
                                           exam_overrides: { exam_date: exam_date })
  end

  shared_examples('rejected by daily limit') do
    it 'request is rejected' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: exam_date)

      post_json '/register', client_data.merge(exam_data)

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to match({
        'status' => 'ERROR',
        'error'  => a_collection_including(
          "daily registration limit for #{exam_data[:exam_date]} reached",
        ),
      })
    end
  end

  context 'with global daily limit already reached' do
    let(:configuration) { super().merge(daily_registration_limit: daily_registration_limit) }

    include_examples('rejected by daily limit')
  end

  context 'with custom daily limit already reached' do
    before do
      db.daily_overrides.create(date: exam_date, registration_limit: daily_registration_limit)
    end

    include_examples('rejected by daily limit')
  end
end

require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:daily_registration_limit) { 5 }

  before do
    mock_config_with(daily_registration_limit: daily_registration_limit)
  end

  context 'with daily limit already reached' do
    let(:exam_date) { Faker::Date.forward(days: 60) }

    before do
      create_many_clients_with_registrations(daily_registration_limit,
                                             exam_overrides: { exam_date: exam_date })
    end

    it 'request is rejected' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: exam_date)

      post_json '/register', client_data.merge(exam_data)

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => ["daily registration limit for #{exam_data[:exam_date]} reached"],
      })
    end
  end
end

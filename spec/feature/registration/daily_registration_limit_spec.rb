require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:daily_registration_limit) { 5 }

  before do
    allow(CovidForm::Dependencies).to receive(:[]).and_call_original
    allow(CovidForm::Dependencies).to receive(:[]).with(:config).and_return({
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
      daily_registration_limit:              daily_registration_limit,
    })
  end

  context 'with daily limit already reached' do
    let(:exam_date) { Faker::Date.forward(days: 60) }

    before do
      daily_registration_limit.times do
        client_data = attributes_for(:client)
        exam_data   = attributes_for(:exam, exam_date: exam_date)

        # TODO: use multi-insert for this
        client_id = repository.clients.insert(clean_client_data(client_data))
        repository.registrations.insert(
          exam_data.merge({ client_id: client_id, registered_at: Time.now }),
        )
      end
    end

    it 'rejects the request' do
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

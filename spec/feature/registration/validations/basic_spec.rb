require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - basic validations' do
  include CovidForm::TestHelpers::Generic
  include CovidForm::Import[:db]

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
    )

    populate_time_slots
  end

  context 'with invalid email' do
    let(:client_data) { attributes_for(:client_with_invalid_email) }

    it 'request is rejected' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:client][:email] ).to include 'is in invalid format'
    end
  end

  context 'with exam date in the past' do
    let(:exam_data) { attributes_for(:exam_with_past_date) }

    it 'request is rejected' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:exam][:exam_date]).to include 'must not be in the past'
    end
  end

  context 'with nonexistent time_slot_id' do
    let(:exam_data) { attributes_for(:exam, time_slot_id: -1) }

    it 'request is rejected' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:error][0]).to match(/time slot.*does not exist/)
    end
  end
end

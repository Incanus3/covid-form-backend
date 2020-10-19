require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route - validations' do # rubocop:disable Metrics/BlockLength
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:db]

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  let(:allow_registration_for_weekends)       { true }
  let(:allow_registration_for_today_after_10) { true }

  before do
    mock_config_with(
      allow_registration_for_weekends:       allow_registration_for_weekends,
      allow_registration_for_today_after_10: allow_registration_for_today_after_10,
    )

    populate_time_slots
  end

  describe 'basic validations' do
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

  describe 'registration locking' do
    let(:allow_registration_for_today_after_10) { false }

    context 'registration for tomorrow' do
      let(:exam_data) { attributes_for(:exam, exam_date: Utils::Date.tomorrow) }

      it 'is accepted even after 10pm' do
        Timecop.freeze(Utils::Time.today_at(10, 0)) do
          post_json '/register', request_data
        end

        expect(last_response).to be_ok
      end
    end

    context 'registration for today' do
      let(:exam_data) { attributes_for(:exam, exam_date: Date.today) }

      it 'is accepted before 10pm' do
        Timecop.freeze(Utils::Time.today_at(9, 59)) do
          post_json '/register', request_data
        end

        expect(last_response).to be_ok
      end

      it 'is rejected after 10pm' do
        Timecop.freeze(Utils::Time.today_at(10, 0)) do
          post_json '/register', request_data
        end

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error])
          .to include 'registration for today is only possible before 10:00'
      end
    end
  end

  describe 'disallow registration for weekends' do
    let(:allow_registration_for_weekends) { false }

    context 'registration for saturday' do
      let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2050, 1, 1)) }

      it 'is rejected' do
        post_json '/register', request_data

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error] )
          .to include 'registration for examination is only possible for workdays'
      end
    end

    context 'registration for monday' do
      let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2050, 1, 3)) }

      it 'is accepted' do
        post_json '/register', request_data

        expect(last_response).to be_ok
      end
    end
  end

  describe 'repeated registration validations' do
    context 'if the client is already registered for that day' do
      before do
        create_client_with_registration(client_data: client_data, exam_data: exam_data)
      end

      it 'request is rejected' do
        post_json '/register', request_data

        expect(last_response     ).to be_unprocessable
        expect(last_response.json).to eq({
          'status' => 'ERROR',
          'error'  => ["client with insurance_number #{client_data[:insurance_number]} " \
                       "is already registered for #{exam_data[:exam_date]}"],
        })
      end
    end
  end
end

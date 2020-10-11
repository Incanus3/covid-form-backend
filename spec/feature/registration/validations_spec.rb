require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do # rubocop:disable Metrics/BlockLength
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:allow_registration_for_weekends)       { true }
  let(:allow_registration_for_today_after_10) { true }

  before do
    allow(CovidForm::Dependencies).to receive(:resolve).and_call_original
    allow(CovidForm::Dependencies).to receive(:resolve).with(:config).and_return({
      allow_registration_for_weekends:       allow_registration_for_weekends,
      allow_registration_for_today_after_10: allow_registration_for_today_after_10,
    })
  end

  describe 'basic validations' do
    it 'rejects request if the email is invalid' do
      client_data = attributes_for(:client_with_invalid_email)
      exam_data   = attributes_for(:exam)
      data        = client_data.merge(exam_data)

      post_json '/register', data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:email])
        .to include 'is in invalid format'
    end

    it 'rejects request if exam date is in the past' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam_with_past_date)
      data        = client_data.merge(exam_data)

      post_json '/register', data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:exam_date])
        .to include 'must not be in the past'
    end
  end

  describe 'registration locking' do
    let(:allow_registration_for_today_after_10) { false }

    it 'accepts registration for tomorrow even after 10pm' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: Utils::Date.tomorrow)
      data        = client_data.merge(exam_data)

      Timecop.freeze(Utils::Time.today_at(10, 0)) do
        post_json '/register', data
      end

      expect(last_response).to be_ok
    end

    it 'accepts registration for today before 10pm' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: Date.today)
      data        = client_data.merge(exam_data)

      Timecop.freeze(Utils::Time.today_at(9, 59)) do
        post_json '/register', data
      end

      expect(last_response).to be_ok
    end

    it 'rejects registration for today after 10pm' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: Date.today)
      data        = client_data.merge(exam_data)

      Timecop.freeze(Utils::Time.today_at(10, 0)) do
        post_json '/register', data
      end

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:error])
        .to include 'registration for today is only possible before 10:00'
    end
  end

  describe 'disallow registration for weekends' do
    let(:allow_registration_for_weekends) { false }

    it 'rejects registration for saturday' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: Date.new(2050, 1, 1))
      data        = client_data.merge(exam_data)

      post_json '/register', data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:error])
        .to include 'exam date must be a weekday'
    end

    it 'accepts registration for monday' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: Date.new(2050, 1, 3))
      data        = client_data.merge(exam_data)

      post_json '/register', data

      expect(last_response).to be_ok
    end
  end

  describe 'repeated registration validations' do
    it 'rejects request if the client is already registered for that day' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam)
      data        = client_data.merge(exam_data)

      client_id = repository.clients.insert(clean_client_data(client_data))
      repository.registrations.insert(
        exam_data.merge({ client_id: client_id, registered_at: Time.now }),
      )

      post_json '/register', data

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => ["client with insurance_number #{client_data[:insurance_number]} " \
                     "is already registered for #{exam_data[:exam_date]}"],
      })
    end
  end
end

require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  describe 'basic validations' do
    it 'rejects request if the email is invalid' do
      client_data = attributes_for(:client_with_invalid_email)
      exam_data   = attributes_for(:exam)
      data        = client_data.merge(exam_data)

      post_json '/register', data

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({ 'status' => 'ERROR', 'email' => ['is in invalid format'] })
    end
  end

  describe 'exam date validations' do
    it 'rejects request if exam date is in the past' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam_with_past_date)
      data        = client_data.merge(exam_data)

      post_json '/register', data

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({
        'status'    => 'ERROR',
        'exam_date' => ['must not be in the past'],
      })
    end

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

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => ['registration for today is only possible before 10:00'],
      })
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

require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.describe 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  it 'rejects request if the email is invalid' do
    client_data = attributes_for(:client_with_invalid_email)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    post_json '/register', data

    expect(last_response     ).to be_unprocessable
    expect(last_response.json).to eq({ 'status' => 'ERROR', 'email' => ['is in invalid format'] })
  end

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

  it 'rejects request if the client is already registered for that day' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    client_id = repository.clients.insert(clean_client_data(client_data))
    repository.registrations.insert(exam_data.merge({ client_id: client_id }))

    post_json '/register', data

    expect(last_response     ).to be_unprocessable
    expect(last_response.json).to eq({
      'status' => 'ERROR',
      'error'  => ["client with insurance_number #{client_data[:insurance_number]} " \
                   "is already registered for #{exam_data[:exam_date]}"],
    })
  end
end

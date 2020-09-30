require 'spec_helper'
require 'app/dependencies'
require 'app/web/validation/contracts'

RSpec.describe 'POST /register route' do
  include CovidForm::Import[:db]

  def clean_client_data(data)
    CovidForm::Web::Validation::ClientSchema.call(data).to_h
  end

  it 'accepts properly formed request' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    post_json '/register', data

    expect(last_response     ).to be_ok
    expect(last_response.json).to eq({ 'status' => 'OK' })
  end

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
      'exam_date' => ['must not be in the past']
    })
  end

  it 'rejects request if client already exists' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    db[:clients].insert(clean_client_data(client_data))

    post_json '/register', data

    expect(last_response     ).to be_conflict
    expect(last_response.json).to eq({
      'status' => 'ERROR',
      'error'  => "client with insurance_number #{client_data[:insurance_number]} already exists"
    })
  end
end

require 'spec_helper'
require 'app/dependencies'

RSpec.describe 'POST /register route' do
  include CovidForm::Import[:db]

  it 'accepts properly formed request' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    post_json '/register', data

    expect(last_response     ).to be_ok
    expect(last_response.json).to eq({ 'status' => 'OK' })
  end

  it 'rejects malformed request' do
    client_data = attributes_for(:invalid_client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    post_json '/register', data

    expect(last_response     ).to be_unprocessable
    expect(last_response.json).to eq({ 'status' => 'ERROR', 'email' => ['is in invalid format'] })
  end

  it 'rejects request if client already exists' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    db[:clients].insert(client_data)

    post_json '/register', data

    expect(last_response     ).to be_conflict
    expect(last_response.json).to eq({
      'status' => 'ERROR',
      'error'  => "client with insurance_number #{client_data[:insurance_number]} already exists"
    })
  end
end

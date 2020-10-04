require 'spec_helper'
require 'app/dependencies'
require 'app/web/validation/contracts'

RSpec.describe 'POST /register route' do
  include CovidForm::Import[:repository]

  def clean_client_data(data)
    CovidForm::Web::Validation::ClientSchema.call(data).to_h
  end

  def serialize(entity)
    entity.to_h.transform_values { |val| val.is_a?(Date) ? val.to_s : val }
  end

  it 'creates a new client and a registration' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)

    post_json '/register', data

    client        = repository.clients[insurance_number: client_data[:insurance_number]]
    registration  = repository.registrations[client_id: client.id]
    response_data = last_response.symbolized_json

    expect(last_response               ).to be_ok
    expect(response_data[:status]      ).to eq 'OK'
    expect(response_data[:client]      ).to eq client.to_h
    expect(response_data[:registration]).to eq serialize(registration)
    expect(client.first_name           ).to eq client_data[:first_name]
    expect(registration.exam_type      ).to eq exam_data[:exam_type]

    is_expected.to have_sent_email
      .from('covid@test.cz')
      .to(client_data[:email])
      .matching_subject(/test registration/)
      .matching_body(/registration was successful/)
      .with_no_attachments
  end

  it 'updates existing client (by insurance number) and creates a new registration' do
    client_data = attributes_for(:client)
    exam_data   = attributes_for(:exam)
    data        = client_data.merge(exam_data)
    client_id   = repository.clients.insert(clean_client_data(client_data))

    data[:first_name] = 'Updated'

    post_json '/register', data

    updated_client = repository.clients.with_pk!(client_id)
    registration   = repository.registrations[client_id: client_id]
    response_data  = last_response.symbolized_json

    expect(last_response               ).to be_ok
    expect(response_data[:status]      ).to eq 'OK'
    expect(response_data[:client]      ).to eq updated_client.to_h
    expect(response_data[:registration]).to eq serialize(registration)
    expect(updated_client.first_name   ).to eq 'Updated'
    expect(registration.exam_type      ).to eq exam_data[:exam_type]
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

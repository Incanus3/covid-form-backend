require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:client_data)  { attributes_for(:client)      }
  let(:exam_data)    { attributes_for(:exam)        }
  let(:request_data) { client_data.merge(exam_data) }

  context 'with a new client' do
    it 'creates the client' do
      post_json '/register', request_data

      client = repository.clients[insurance_number: client_data[:insurance_number]]

      expect(serialize(client)).to include clean_client_data(client_data)
    end

    it 'creates a registration' do
      post_json '/register', request_data

      client       = repository.clients[insurance_number: client_data[:insurance_number]]
      registration = repository.registrations[client_id: client.id]

      expect(serialize(registration))
        .to include serialize(exam_data.merge({ client_id: client.id }))
    end

    it 'returns a response including both' do
      post_json '/register', request_data

      response_data = last_response.symbolized_json

      expect(last_response               ).to be_ok
      expect(response_data[:status]      ).to eq 'OK'
      expect(response_data[:client]      ).to include clean_client_data(client_data)
      expect(response_data[:registration])
        .to include serialize(exam_data.merge({ client_id: response_data[:client][:id] }))
    end

    it 'sends and informational email' do
      post_json '/register', request_data

      is_expected.to have_sent_email
        .from('covid@test.cz')
        .to(client_data[:email])
        .matching_subject(/test registration/)
        .matching_body(/registration was successful/)
        .with_no_attachments
    end
  end

  context 'with an existing client (insurance number)' do
    it 'updates the client' do
      client_id = repository.clients.insert(clean_client_data(client_data))

      request_data[:first_name] = 'Updated'

      post_json '/register', request_data

      updated_client = repository.clients.with_pk!(client_id)

      expect(updated_client.first_name).to eq 'Updated'
    end
  end
end
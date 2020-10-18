require 'spec_helper'
require_relative 'registration/helpers'

RSpec.feature 'GET /export route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:db]

  before do
    populate_time_slots
  end

  let(:client_data) { attributes_for(:client) }
  let(:exam_data)   { attributes_for(:exam)   }

  context 'without authentication' do
    it 'returns an appropriate error response' do
      get '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq 'authentication failed: missing Authorization header'
    end
  end

  context 'with malformed authentication header' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq 'authentication failed: malformed Authorization header'
    end
  end

  context 'with unrecognized authentication method' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'MagicToken XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error'])
        .to eq "authentication failed: unrecognized authentication method 'MagicToken'"
    end
  end

  context 'with bad password' do
    it 'returns an appropriate error response' do
      header 'Authorization', 'Password XXX'
      get    '/export'

      expect(last_response).to be_unauthorized
      expect(last_response.json['error']).to eq 'authentication failed: bad credentials'
    end
  end

  context 'with valid authentication' do
    context 'on successful export' do
      it 'returns a CSV with exported data', :no_transaction do
        client    = db.clients.create(clean_client_data(client_data))
        time_slot = db.time_slots.find(exam_data[:time_slot_id])

        db.registrations.create(
          exam_data.merge({ client_id: client.id, registered_at: Time.now }),
        )

        header 'Authorization', 'Password admin'
        get    '/export'

        expect(last_response).to be_ok

        data       = last_response.json['csv'].split("\n")
        time_range = formatted_time_range(time_slot)

        expect(data[0]).to match(/;requestor_type;.*;time_range;.*;email/)
        expect(data[1]).to match(
          /;"#{exam_data[:requestor_type]}";.*;"#{time_range}";.*;"#{client_data[:email]}"/,
        )
      end
    end

    context 'when export fails' do
      before { allow(db.gateways[:default]).to receive(:options).and_return({}) }

      it 'returns a meaningful error', :no_transaction do
        client = db.clients.create(clean_client_data(client_data))
        db.registrations.create(
          exam_data.merge({ client_id: client.id, registered_at: Time.now }),
        )

        header 'Authorization', 'Password admin'
        get    '/export'

        expect(last_response).to be_unprocessable
        expect(last_response.json['status']  ).to eq 'ERROR'
        expect(last_response.json['error'][0]).to match(/could not connect to server/)
      end
    end
  end
end

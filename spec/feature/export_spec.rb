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
        time_range = formatted_time_range(time_slot, remove_leading_zeros: false)

        expect(data[0]).to match(/;email;requestor_type;.*;time_range;/)
        expect(data[1]).to match(
          /;"#{client_data[:email]}";"#{exam_data[:requestor_type]}";.*;"#{time_range}";/,
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

    context 'with bad date params' do
      it 'returns a proper validation error' do
        header 'Authorization', 'Password admin'
        get    '/export', start_date: Date.today, end_date: Date.today - 10

        expect(last_response).to be_unprocessable
        expect(last_response.symbolized_json).to match({
          status: 'ERROR',
          error:  a_collection_including('end_date must be after start_date'),
        })
      end
    end
  end
end

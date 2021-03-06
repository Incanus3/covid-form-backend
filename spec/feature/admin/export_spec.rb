require 'spec_helper'
require 'spec/feature/helpers'

RSpec.feature 'GET /admin/export route' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration
  include CovidForm::TestHelpers::Authentication

  before do
    populate_exam_types
    populate_time_slots
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  let(:client_data) { attributes_for(:client, last_name: 'Ěščřžýáíé') }
  let(:exam_data)   { attributes_for(:exam)                           }

  context 'on successful export' do
    let(:client)    { db.clients.create(clean_client_data(client_data)) }
    let(:time_slot) { db.time_slots.find(exam_data[:time_slot_id])      }

    before do
      db.registrations.create(
        exam_data.merge({ client_id: client.id, registered_at: Time.now }),
      )
    end

    context 'with CSV_ENCODING unset' do
      it 'returns UTF-8 encoded CSV with exported data', :no_transaction do
        get '/admin/export'

        expect(last_response).to be_ok

        data       = last_response.body.split("\n")
        time_range = formatted_time_range(time_slot, remove_leading_zeros: false)

        expect(last_response.headers['Content-Type']).to eq 'text/csv;charset=utf-8'
        expect(last_response.body.is_utf8?).to be true
        expect(data[0]).to match(/last_name;.*;time_range;.*;email/)
        expect(data[1]).to match(
          /"#{client_data[:last_name]}";.*;"#{time_range}";.*;"#{client_data[:email]}"/,
        )
      end
    end

    context 'with CSV_ENCODING set' do
      let(:postgres_encoding) { 'WIN1250'      }
      let(:ruby_encoding)     { 'Windows-1250' }

      before do
        ENV['CSV_ENCODING'] = postgres_encoding
      end

      after do
        ENV.delete('CSV_ENCODING')
      end

      it 'returns CSV with exported data encoded as desired', :no_transaction do
        get '/admin/export'

        expect(last_response).to be_ok

        data       = last_response.body.encode('UTF-8', ruby_encoding).split("\n")
        time_range = formatted_time_range(time_slot, remove_leading_zeros: false)

        expect(last_response.headers['Content-Type'])
          .to eq "text/csv;charset=#{ruby_encoding.downcase}"
        expect(last_response.body.is_utf8?).to be false
        expect(data[0]).to match(/last_name;.*;time_range;.*;email/)
        expect(data[1]).to match(
          /"#{client_data[:last_name]}";.*;"#{time_range}";.*;"#{client_data[:email]}"/,
        )
      end
    end
  end

  context 'when export fails' do
    before { allow(db.gateways[:default]).to receive(:options).and_return({}) }

    it 'returns a meaningful error', :no_transaction do
      client = db.clients.create(clean_client_data(client_data))
      db.registrations.create(
        exam_data.merge({ client_id: client.id, registered_at: Time.now }),
      )

      get '/admin/export'

      expect(last_response).to be_unprocessable
      expect(last_response.json['status']  ).to eq 'ERROR'
      expect(last_response.json['error'][0]).to match(
        /could\ not\ connect\ to\ server|
        (database|role)\ .*\ does\ not\ exist|
        no\ password\ supplied/x,
      )
    end
  end

  context 'with bad date params' do
    it 'returns a proper validation error' do
      get '/admin/export', start_date: Date.today, end_date: Date.today - 10

      expect(last_response).to be_unprocessable
      expect(last_response.symbolized_json).to match({
        status: 'ERROR',
        code:   'validation_failed',
        error:  a_collection_including('end_date must be after start_date'),
      })
    end
  end
end

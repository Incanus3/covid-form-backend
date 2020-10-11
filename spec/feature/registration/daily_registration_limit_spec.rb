require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:repository]

  let(:daily_registration_limit) { 5 }

  before do
    mock_config_with(daily_registration_limit: daily_registration_limit)
  end

  context 'with daily limit already reached' do
    let(:exam_date) { Faker::Date.forward(days: 60) }

    before do
      # TODO: use multi-insert for this
      # daily_registration_limit.times do
      #   client_data = attributes_for(:client)
      #   exam_data   = attributes_for(:exam, exam_date: exam_date)

      #   client_id = repository.clients.insert(clean_client_data(client_data))
      #   repository.registrations.insert(
      #     exam_data.merge({ client_id: client_id, registered_at: Time.now }),
      #   )
      # end

      # NOTE: this is more effective, but not nearly as readable
      # does the speed really matter with these numbers?
      client_attrs_list = attributes_for_list(:client, daily_registration_limit)
        .map { clean_client_data(_1) }
      client_records = repository.clients.dataset.returning.multi_insert(client_attrs_list)

      exam_attrs_list = attributes_for_list(:exam, daily_registration_limit, exam_date: exam_date)
      registration_attrs_list = client_records.zip(exam_attrs_list)
        .map { |(client_record, exam_attrs)|
          exam_attrs.merge(client_id: client_record[:id], registered_at: Time.now)
        }
      repository.registrations.multi_insert(registration_attrs_list)
    end

    it 'rejects the request' do
      client_data = attributes_for(:client)
      exam_data   = attributes_for(:exam, exam_date: exam_date)

      post_json '/register', client_data.merge(exam_data)

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to eq({
        'status' => 'ERROR',
        'error'  => ["daily registration limit for #{exam_data[:exam_date]} reached"],
      })
    end
  end
end

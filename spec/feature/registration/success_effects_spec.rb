require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /registration/create route - success effects' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration

  before do
    mock_config_with(
      enable_registration_deadline:    false,
      allow_registration_for_weekends: true,
    )

    populate_exam_types
    populate_time_slots
  end

  let(:client_data)  { attributes_for(:client)                  }
  let(:exam_data)    { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  context 'with a new client' do
    it 'creates the client' do
      post_json '/registration/create', request_data

      client = db.clients.find_by_insurance_number(client_data[:insurance_number])

      expect(serialize(client)).to include clean_client_data(client_data)
    end

    it 'creates a registration' do
      post_json '/registration/create', request_data

      client       = db.clients.find_by_insurance_number(client_data[:insurance_number])
      registration = db.registrations.for_client(client).first

      expect(serialize(registration))
        .to include serialize(exam_data.merge({ client_id: client.id }))
    end

    it 'returns a response including both' do
      post_json '/registration/create', request_data

      response_data = last_response.symbolized_json

      expect(last_response               ).to be_ok
      expect(response_data[:status]      ).to eq 'OK'
      expect(response_data[:client]      ).to include clean_client_data(client_data)
      expect(response_data[:registration])
        .to include serialize(exam_data.merge({ client_id: response_data[:client][:id] }))
    end

    it 'sends and informational email' do
      post_json '/registration/create', request_data

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
      client = db.clients.create(clean_client_data(client_data))

      client_data[:first_name] = 'Updated'

      post_json '/registration/create', request_data

      updated_client = db.clients.find(client.id)

      expect(updated_client.first_name).to eq 'Updated'
    end
  end
end

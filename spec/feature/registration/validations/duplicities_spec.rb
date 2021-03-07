require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - duplicity validations' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      enable_registration_deadline:    false,
      allow_registration_for_weekends: true,
    )

    populate_exam_types
    populate_time_slots
  end

  describe 'repeated registration validations' do
    context 'if the client is already registered for that day' do
      before do
        create_client_with_registration(client_data: client_data, exam_data: exam_data)
      end

      it 'request is rejected' do
        post_json '/register', request_data

        expect(last_response).to be_unprocessable
        expect(last_response.symbolized_json).to eq({
          status: 'ERROR',
          code:   'validation_failed',
          error:  [
            "client with insurance_number #{client_data[:insurance_number]} " \
            "is already registered for #{exam_data[:exam_date]}",
          ],
        })
      end
    end
  end
end

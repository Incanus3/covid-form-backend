require 'spec_helper'
require 'spec/feature/registration/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - duplicity validations' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:db]

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
    )

    populate_time_slots
  end

  describe 'repeated registration validations' do
    context 'if the client is already registered for that day' do
      before do
        create_client_with_registration(client_data: client_data, exam_data: exam_data)
      end

      it 'request is rejected' do
        post_json '/register', request_data

        expect(last_response     ).to be_unprocessable
        expect(last_response.json).to eq({
          'status' => 'ERROR',
          'error'  => ["client with insurance_number #{client_data[:insurance_number]} " \
                       "is already registered for #{exam_data[:exam_date]}"],
        })
      end
    end
  end
end

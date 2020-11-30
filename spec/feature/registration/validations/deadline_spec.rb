require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - lock after deadline' do
  include CovidForm::TestHelpers::Generic
  include CovidForm::Import[:db]

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: false,
    )

    populate_exam_types
    populate_time_slots
  end

  context 'registration for tomorrow' do
    let(:exam_data) { attributes_for(:exam, exam_date: Utils::Date.tomorrow) }

    it 'is accepted even after 10pm' do
      Timecop.freeze(Utils::Time.today_at(10, 0)) do
        post_json '/register', request_data
      end

      expect(last_response).to be_ok
    end
  end

  context 'registration for today' do
    let(:exam_data) { attributes_for(:exam, exam_date: Date.today) }

    it 'is accepted before 10pm' do
      Timecop.freeze(Utils::Time.today_at(9, 59)) do
        post_json '/register', request_data
      end

      expect(last_response).to be_ok
    end

    it 'is rejected after 10pm' do
      Timecop.freeze(Utils::Time.today_at(10, 0)) do
        post_json '/register', request_data
      end

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:error])
        .to include 'registration for today is only possible before 10:00'
    end
  end
end

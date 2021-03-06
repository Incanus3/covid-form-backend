require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /registration/create route - weekday validation' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes

  def next_week_day(wday)
    date  = Date.today + 1
    date += 1 until date.wday == wday
    date
  end

  let(:client_data ) { attributes_for(:client)                  }
  let(:exam_data   ) { attributes_for(:exam)                    }
  let(:request_data) { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      enable_registration_deadline:    false,
      allow_registration_for_weekends: false,
    )

    populate_exam_types
    populate_time_slots
  end

  context 'registration for monday' do
    let(:exam_data) { attributes_for(:exam, exam_date: next_week_day(1)) }

    it 'is accepted' do
      post_json '/registration/create', request_data

      expect(last_response).to be_ok
    end
  end

  context 'registration for saturday' do
    let(:exam_data) { attributes_for(:exam, exam_date: next_week_day(6)) }

    it 'is rejected' do
      post_json '/registration/create', request_data

      response_data = last_response.symbolized_json

      expect(last_response).to be_unprocessable
      expect(response_data[:status]).to eq 'ERROR'
      expect(response_data[:error] )
        .to include 'registration for examination is only possible for workdays'
    end
  end
end

require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /registration/create route validations - allowed dates' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes

  let(:client_data )    { attributes_for(:client)                  }
  let(:exam_data   )    { attributes_for(:exam)                    }
  let(:request_data)    { { client: client_data, exam: exam_data } }

  before do
    mock_config_with(
      week_starts_on:                  6, # saturday
      open_registration_in_weeks:      1,
      close_registration_in_weeks:     1,
      allow_registration_for_weekends: true,
    )

    populate_exam_types
    populate_time_slots

    Timecop.freeze(Date.new(2021, 3, 3)) # wednesday
  end

  after do
    Timecop.return
  end

  context 'registration for this friday' do
    let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2021, 3, 5)) }

    it 'is rejected' do
      post_json '/registration/create', request_data

      expect(last_response).to be_unprocessable
      expect(last_response.symbolized_json).to match({
        status: 'ERROR',
        code:   'validation_failed',
        error:  a_collection_including(a_string_matching(/not a valid exam date/)),
      })
    end
  end

  context 'registration for this saturday' do
    let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2021, 3, 6)) }

    it 'is accepted' do
      post_json '/registration/create', request_data

      expect(last_response).to be_ok
    end
  end

  context 'registration for next friday' do
    let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2021, 3, 12)) }

    it 'is accepted' do
      post_json '/registration/create', request_data

      expect(last_response).to be_ok
    end
  end

  context 'registration for next saturday' do
    let(:exam_data) { attributes_for(:exam, exam_date: Date.new(2021, 3, 13)) }

    it 'is rejected' do
      post_json '/registration/create', request_data

      expect(last_response).to be_unprocessable
      expect(last_response.symbolized_json).to match({
        status: 'ERROR',
        code:   'validation_failed',
        error:  a_collection_including(a_string_matching(/not a valid exam date/)),
      })
    end
  end
end

require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /registration/create route - lock after deadline' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes

  let(:client_data )    { attributes_for(:client)                  }
  let(:exam_data   )    { attributes_for(:exam)                    }
  let(:request_data)    { { client: client_data, exam: exam_data } }
  let(:deadline_offset) { 'to be set'                              }

  before do
    mock_config_with(
      enable_registration_deadline:         true,
      allow_registration_for_weekends:      true,
      registration_deadline_offset_minutes: deadline_offset,
    )

    populate_exam_types
    populate_time_slots
  end

  context 'with positive deadline offset' do
    let(:deadline_offset) { 600 }

    context 'registration for tomorrow' do
      let(:exam_data) { attributes_for(:exam, exam_date: Utils::Date.tomorrow) }

      it 'is accepted even after deadline time' do
        Timecop.freeze(Utils::Time.today_at(10, 0)) do
          post_json '/registration/create', request_data
        end

        expect(last_response).to be_ok
      end
    end

    context 'registration for today' do
      let(:exam_data) { attributes_for(:exam, exam_date: Date.today) }

      it 'is accepted before deadline time' do
        Timecop.freeze(Utils::Time.today_at(9, 59)) do
          post_json '/registration/create', request_data
        end

        expect(last_response).to be_ok
      end

      it 'is rejected after deadline time' do
        Timecop.freeze(Utils::Time.today_at(10, 0)) do
          post_json '/registration/create', request_data
        end

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error])
          .to include 'registration for today is only possible before 10:00'
      end
    end
  end

  context 'with negative deadline offset' do
    let(:deadline_offset) { -300 }

    context 'registration for tomorrow' do
      let(:exam_data) { attributes_for(:exam, exam_date: Utils::Date.tomorrow) }

      it 'is accepted before deadline time' do
        Timecop.freeze(Utils::Time.today_at(18, 59)) do
          post_json '/registration/create', request_data
        end

        expect(last_response).to be_ok
      end

      it 'is rejected after deadline time' do
        Timecop.freeze(Utils::Time.today_at(19, 0)) do
          post_json '/registration/create', request_data
        end

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error])
          .to include 'registration for today is only possible before 19:00'
      end
    end

    context 'registration for today' do
      let(:exam_data) { attributes_for(:exam, exam_date: Date.today) }

      it 'is rejected even before deadline time' do
        Timecop.freeze(Utils::Time.today_at(18, 59)) do
          post_json '/registration/create', request_data
        end

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error])
          .to include 'registration for today is only possible before 19:00'
      end

      it 'is rejected after deadline time' do
        Timecop.freeze(Utils::Time.today_at(19, 0)) do
          post_json '/registration/create', request_data
        end

        response_data = last_response.symbolized_json

        expect(last_response).to be_unprocessable
        expect(response_data[:status]).to eq 'ERROR'
        expect(response_data[:error])
          .to include 'registration for today is only possible before 19:00'
      end
    end
  end
end

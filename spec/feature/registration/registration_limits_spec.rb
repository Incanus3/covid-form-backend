require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'POST /register route - registration limits' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Configuration
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration

  let(:client_data) { attributes_for(:client)       }
  let(:exam_date)   { Faker::Date.forward(days: 60) }
  let(:time_slot)   { db.time_slots.first           }
  let(:exam_data)   {
    attributes_for(:exam,
                   exam_date:    exam_date,
                   time_slot_id: time_slot.id)
  }

  let(:daily_registration_limit) { 5 }
  let(:configuration)            {
    {
      allow_registration_for_weekends:     true,
      enable_time_slot_registraiton_limit: false,
      enable_registration_deadline:        false,
    }
  }

  before do
    populate_exam_types
    populate_time_slots

    mock_config_with(configuration)

    create_many_clients_with_registrations(
      daily_registration_limit, exam_overrides: {
        exam_date: exam_date, time_slot_id: db.time_slots.first.id
      }
    )
  end

  shared_examples('rejected by limit') do |limit_type|
    it 'request is rejected' do
      post_json '/register', { client: client_data, exam: exam_data }

      expect(last_response     ).to be_unprocessable
      expect(last_response.json).to match({
        'status' => 'ERROR',
        'error'  => a_collection_including(
          a_string_matching(/#{limit_type} registration limit for .* reached/),
        ),
      })
    end
  end

  context 'global daily limit' do
    context 'with daily limit already' do
      let(:configuration) { super().merge(daily_registration_limit: daily_registration_limit) }

      include_examples 'rejected by limit', 'daily'
    end

    context 'with slot limit reached' do
      let(:configuration) {
        super().merge(
          enable_time_slot_registraiton_limit: true,
          daily_registration_limit:            (
            daily_registration_limit * db.time_slots.root.sum(:limit_coefficient) /
            time_slot.limit_coefficient
          ),
        )
      }

      include_examples 'rejected by limit', 'time slot'
    end
  end

  context 'overridden daily limit' do
    context 'with daily limit reached' do
      before do
        db.daily_overrides.create(date: exam_date, registration_limit: daily_registration_limit)
      end

      include_examples 'rejected by limit', 'daily'
    end

    context 'with slot limit reached' do
      before do
        db.daily_overrides.create(
          date: exam_date, registration_limit: (
            daily_registration_limit * db.time_slots.root.sum(:limit_coefficient) /
            time_slot.limit_coefficient
          )
        )
      end

      include_examples 'rejected by limit', 'time slot'
    end
  end
end

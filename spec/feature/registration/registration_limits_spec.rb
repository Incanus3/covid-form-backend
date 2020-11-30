require 'spec_helper'
require 'app/dependencies'
require_relative 'helpers'

RSpec.feature 'POST /register route - registration limits' do
  include CovidForm::TestHelpers::Registration
  include CovidForm::Import[:db]

  let(:client_data) { attributes_for(:client)       }
  let(:exam_date)   { Faker::Date.forward(days: 60) }
  let(:exam_data)   {
    attributes_for(:exam,
                   exam_date:    exam_date,
                   time_slot_id: db.time_slots.first.id)
  }

  let(:daily_registration_limit) { 5 }
  let(:configuration)            {
    {
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
      enable_time_slot_registraiton_limit:   false,
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

  shared_examples('rejected by daily limit') do |limit_type|
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

      include_examples 'rejected by daily limit', 'daily'
    end

    context 'with slot limit reached' do
      let(:configuration) {
        super().merge(
          daily_registration_limit:            daily_registration_limit * db.time_slots.count_all,
          enable_time_slot_registraiton_limit: true,
        )
      }

      include_examples 'rejected by daily limit', 'time slot'
    end
  end

  context 'overridden daily limit' do
    context 'with daily limit reached' do
      before do
        db.daily_overrides.create(date: exam_date, registration_limit: daily_registration_limit)
      end

      include_examples 'rejected by daily limit', 'daily'
    end

    context 'with slot limit reached' do
      before do
        db.daily_overrides.create(
          date: exam_date, registration_limit: daily_registration_limit * db.time_slots.count_all,
        )
      end

      include_examples 'rejected by daily limit', 'time slot'
    end
  end
end

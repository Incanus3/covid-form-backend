require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'GET /capacity/available_time_slots' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration

  before do
    populate_exam_types
    populate_time_slots
    populate_time_slot_exam_types

    create_client_with_registration(exam_overrides: { exam_date: Date.today })
  end

  it 'works' do
    get '/capacity/available_time_slots', exam_type: 'pcr'

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:     'OK',
      time_slots: (
        be_an(Array)
        .and(all(be_a(Hash)))
        .and(have(morning_slots.count).elements)
        .and(include(a_hash_including(
          name:       morning_slots.first.name,
          time_range: formatted_time_range(morning_slots.first),
        )))
      ),
    })
  end
end

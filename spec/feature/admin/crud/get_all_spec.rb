require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions - get_all' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::Authentication

  before do
    populate_exam_types
    populate_time_slots
    populate_time_slot_exam_types
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  it 'works' do
    get '/admin/crud/time_slots'

    time_slots = db.time_slots.all

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:     'OK',
      time_slots: (
        be_an(Array)
        .and(all(be_a(Hash)))
        .and(have(time_slots.count).elements)
        .and(include(a_hash_including(
          name:              time_slots.first.name,
          limit_coefficient: time_slots.first.limit_coefficient,
        )))
      ),
    })
  end

  it 'supports loading related records' do
    get '/admin/crud/time_slots', with: [:exam_types]

    time_slots = db.time_slots.all_by_id_with(:exam_types)

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:     'OK',
      time_slots: include(a_hash_including(
        exam_types: (
          be_an(Array)
          .and(all(be_a(Hash)))
          .and(have(time_slots.first.exam_types.count).elements)
          .and(include(a_hash_including(
            id:          time_slots.first.exam_types.first.id,
            description: time_slots.first.exam_types.first.description,
          )))
        ),
      )),
    })
  end
end

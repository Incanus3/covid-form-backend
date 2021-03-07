require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions - delete' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Registration
  include CovidForm::TestHelpers::Authentication

  before do
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  def delete_time_slot(id)
    delete "/admin/crud/time_slots/#{id}"
  end

  let!(:time_slot) {
    db.time_slots.create({
      name:              'test slot',
      start_time:        Utils::Time.today_at(8,  0),
      end_time:          Utils::Time.today_at(10, 0),
      limit_coefficient: 7,
    })
  }

  it 'deletes the record' do
    delete_time_slot(time_slot.id)

    expect(db.time_slots.count_all).to eq 0
  end

  it 'returns success response with no content' do
    delete_time_slot(time_slot.id)

    expect(last_response).to be_no_content
    expect(last_response.body).to eq ''
  end

  context 'with nonexistent id' do
    it 'returns appropriate error response' do
      delete_time_slot(0)

      expect(last_response).to be_not_found
      expect(last_response.symbolized_json).to match(
        status: 'ERROR',
        code:   'not_found',
        error:  'time slot with id 0 not found',
      )
    end
  end

  context 'with existing registration for time slot' do
    before do
      populate_exam_types
      create_client_with_registration(exam_overrides: { time_slot_id: time_slot.id })
    end

    it 'returns appropriate error response' do
      delete_time_slot(time_slot.id)

      expect(last_response).to be_forbidden
      expect(last_response.symbolized_json).to match(
        status: 'ERROR',
        code:   'forbidden',
        error:  "time slot with id #{time_slot.id} has related records",
      )
    end
  end
end

require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions - update' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Authentication

  before do
    populate_exam_types
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  def update(id, **attributes)
    put_json "/admin/crud/time_slots/#{id}", attributes
  end

  let!(:time_slot) {
    db.time_slots.create({
      name:              'test slot',
      start_time:        Utils::Time.today_at(8,  0),
      end_time:          Utils::Time.today_at(10, 0),
      limit_coefficient: 7,
    })
  }

  it 'updates the record' do
    update(time_slot.id, name: 'u', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

    updated = db.time_slots.find(time_slot.id)

    expect(updated.name             ).to eq 'u'
    expect(updated.start_time       ).to eq Utils::Time.today_at( 9, 0)
    expect(updated.end_time         ).to eq Utils::Time.today_at(11, 0)
    expect(updated.limit_coefficient).to eq 8
  end

  it 'returns the updated record' do
    update(time_slot.id, name: 'u', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:    'OK',
      time_slot: {
        id:                time_slot.id,
        name:              'u',
        start_time:        '09:00',
        end_time:          '11:00',
        limit_coefficient: 8,
      },
    })
  end

  it 'supports setting 1:N relationships' do
    db.time_slot_exam_types.create(time_slot_id: time_slot.id, exam_type: 'pcr')

    update(
      time_slot.id, name: 'u', start_time: '09:00', end_time: '11:00', limit_coefficient: 8,
      exam_types: ['ag']
    )

    updated_time_slot = db.time_slots.root.combine(:exam_types).by_pk(time_slot.id).one!

    expect(updated_time_slot.exam_types).to     include(an_object_having_attributes(id: 'ag'))
    expect(updated_time_slot.exam_types).not_to include(an_object_having_attributes(id: 'pcr'))
  end

  context 'with nonexistent id' do
    it 'returns appropriate error response' do
      update(0, name: 'u', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

      expect(last_response).to be_not_found
      expect(last_response.symbolized_json).to match({
        status: 'ERROR',
        code:   'not_found',
        error:  'time slot with id 0 not found',
      })
    end
  end

  context 'with missing or invalid fields' do
    it 'returns appropriate error response' do
      update(time_slot.id, name: 123, start_time: 'invalid', limit_coefficient: 'invalid')

      expect(last_response).to be_unprocessable
      expect(last_response.symbolized_json).to match({
        status:            'ERROR',
        code:              'validation_failed',
        name:              ['must be a string'],
        start_time:        ['must be a time'],
        end_time:          ['is missing'],
        limit_coefficient: ['must be an integer'],
      })
    end
  end

  context 'when time slot with same name already exists' do
    before do
      db.time_slots.create({
        name:              'existing',
        start_time:        Utils::Time.today_at(8,  0),
        end_time:          Utils::Time.today_at(10, 0),
        limit_coefficient: 7,
      })
    end

    it 'returns appropriate error response' do
      update(
        time_slot.id, name: 'existing', start_time: '09:00', end_time: '11:00', limit_coefficient: 8
      )

      expect(last_response).to be_forbidden
      expect(last_response.symbolized_json).to match(
        status: 'ERROR',
        code:   'forbidden',
        error:  'time slot violates unique constraint',
      )
    end
  end
end

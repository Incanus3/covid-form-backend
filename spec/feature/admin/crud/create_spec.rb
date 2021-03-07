require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions - create' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::ExamTypes
  include CovidForm::TestHelpers::Authentication

  before do
    populate_exam_types
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  def create(**attributes)
    post_json '/admin/crud/time_slots', attributes
  end

  it 'creates the record' do
    create(name: 'test', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

    created = db.time_slots.first

    expect(created.name             ).to eq 'test'
    expect(created.start_time       ).to eq Utils::Time.today_at( 9, 0)
    expect(created.end_time         ).to eq Utils::Time.today_at(11, 0)
    expect(created.limit_coefficient).to eq 8
  end

  it 'returns the created record' do
    create(name: 'test', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

    created = db.time_slots.first

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:    'OK',
      time_slot: {
        id:                created.id,
        name:              'test',
        start_time:        '09:00',
        end_time:          '11:00',
        limit_coefficient: 8,
      },
    })
  end

  it 'supports setting 1:N relationships' do
    create(
      name: 'test', start_time: '09:00', end_time: '11:00', limit_coefficient: 8,
      exam_types: ['ag']
    )

    created = db.time_slots.root.combine(:exam_types).first

    expect(created.exam_types).to     include(an_object_having_attributes(id: 'ag'))
    expect(created.exam_types).not_to include(an_object_having_attributes(id: 'pcr'))
  end

  context 'with missing or invalid fields' do
    it 'returns appropriate error response' do
      create(name: 123, start_time: 'invalid', limit_coefficient: 'invalid')

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
      create(name: 'existing', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

      expect(last_response).to be_forbidden
      expect(last_response.symbolized_json).to match(
        status: 'ERROR',
        code:   'forbidden',
        error:  'time slot violates unique constraint',
      )
    end
  end
end

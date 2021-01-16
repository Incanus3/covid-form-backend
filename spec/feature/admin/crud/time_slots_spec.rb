require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::TimeSlots
  include CovidForm::TestHelpers::Authentication

  before do
    populate_time_slots
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  describe 'get_all action' do
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
  end

  describe 'update action' do
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

    context 'with nonexistent id' do
      it 'returns appropriate error response' do
        update(0, name: 'u', start_time: '09:00', end_time: '11:00', limit_coefficient: 8)

        expect(last_response).to be_not_found
        expect(last_response.symbolized_json).to match({
          status: 'ERROR',
          error:  'TimeSlot with id 0 not found',
        })
      end
    end

    context 'with missing or invalid fields' do
      it 'returns appropriate error response' do
        update(time_slot.id, name: 123, start_time: 'invalid', limit_coefficient: 'invalid')

        expect(last_response).to be_unprocessable
        expect(last_response.symbolized_json).to match({
          status:            'ERROR',
          name:              ['must be a string'],
          start_time:        ['must be a time'],
          end_time:          ['is missing'],
          limit_coefficient: ['must be an integer'],
        })
      end
    end
  end
end

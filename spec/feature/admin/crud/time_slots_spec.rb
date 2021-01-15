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

  describe 'get all action' do
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
end

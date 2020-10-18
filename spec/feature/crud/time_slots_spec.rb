require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'GET /crud/time_slots' do
  include CovidForm::TestHelpers::Generic
  include CovidForm::Import[:db]

  before do
    populate_time_slots
  end

  it 'works' do
    get '/crud/time_slots'

    first_slot = db.time_slots.first

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:     'OK',
      time_slots: (
        be_an(Array)
        .and(all(be_a(Hash)))
        .and(have(db.time_slots.count_all).elements)
        .and(include(a_hash_including(
          name:       first_slot.name,
          time_range: formatted_time_range(first_slot),
        )))
      ),
    })
  end
end

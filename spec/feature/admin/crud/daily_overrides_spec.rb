require 'spec_helper'
require 'spec/feature/helpers'

RSpec.feature 'GET /crud/exam_types route' do
  include CovidForm::Import[:config, :db]
  include CovidForm::TestHelpers::Authentication

  before do
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  let!(:override) { db.daily_overrides.create(date: Date.today + 10, registration_limit: 0) }

  it 'get_all works' do
    get '/admin/crud/daily_overrides'

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:          'OK',
      daily_overrides: a_collection_including({
        id:                 override.id,
        date:               override.date.to_s,
        registration_limit: override.registration_limit,
      }),
    })
  end

  it 'update works' do
    put_json "/admin/crud/daily_overrides/#{override.id}", {
      date: override.date.to_s, registration_limit: 10
    }

    expect(last_response).to be_ok
    expect(last_response.symbolized_json).to match({
      status:         'OK',
      daily_override: {
        id:                 override.id,
        date:               override.date.to_s,
        registration_limit: 10,
      },
    })

    expect(db.daily_overrides.first.registration_limit).to eq 10
  end
end

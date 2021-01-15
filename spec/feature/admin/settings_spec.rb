require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'time slots CRUD actions' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Authentication

  before do
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  describe 'get' do
    it 'works' do
      get '/admin/settings'

      expect(last_response).to be_ok
      expect(last_response.symbolized_json).to match({
        settings: {
          daily_registration_limit: CovidForm::Dependencies[:config][:daily_registration_limit],
        },
      })
    end
  end
end

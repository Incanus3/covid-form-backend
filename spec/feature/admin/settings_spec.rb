require 'spec_helper'
require 'spec/feature/helpers'
require 'app/dependencies'

RSpec.feature 'settings CRUD actions' do
  include CovidForm::Import[:db]
  include CovidForm::TestHelpers::Authentication

  before do
    populate_account_statuses
    create_admin_account
    log_in_admin
  end

  describe 'get' do
    it 'works' do
      get '/admin/crud/settings'

      expect(last_response).to be_ok
      expect(last_response.symbolized_json[:settings]).to include({
        key:   'daily_registration_limit',
        value: CovidForm::Dependencies[:config][:daily_registration_limit],
      })
    end
  end
end

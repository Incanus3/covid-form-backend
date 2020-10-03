require 'database_cleaner/sequel'
require 'factory_bot'
require 'faker'
require 'rspec/collection_matchers'
require 'rack/test'
require 'sequel/core'
require 'simplecov'
require_relative 'helpers/overrides'
require_relative 'helpers/json_requests'

APP_ROOT = File.expand_path('..', __dir__)
ENV['APP_ENV'] = 'test'

$LOAD_PATH.unshift(APP_ROOT)

SimpleCov.start do
  enable_coverage :branch

  add_filter '/spec/'

  add_group 'Application', 'app'
  add_group 'Utilities',   'lib'

  maximum_coverage_drop 3
  minimum_coverage line: 95, branch: 65
  minimum_coverage_by_file 90
end

require 'app/web/app'

# rubocop:disable Style/MethodCallWithArgsParentheses
RSpec.configure do |config|
  config.disable_monkey_patching!

  config.fail_fast = true
  config.run_all_when_everything_filtered = true

  config.filter_run_including :focus
  config.filter_run_excluding :disabled
  config.filter_run_excluding :slow
  config.filter_run_excluding block: nil

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods
  config.include JSONRequests

  Faker::Config.locale = 'cz'

  # TODO: do this relative to __dir__
  I18n.load_path << Dir["#{File.expand_path('config/locales')}/*.yml"]

  config.before(:suite) do
    FactoryBot.find_definitions

    CovidForm::Dependencies.start(:persistence)

    db = CovidForm::Dependencies[:db]

    Sequel.extension(:migration)

    Sequel::Migrator.run(db.sequel_db, 'app/persistence/migrations')

    DatabaseCleaner[:sequel].db = db.sequel_db
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      example.run
    end
  end

  def app
    CovidForm::Web::App
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses

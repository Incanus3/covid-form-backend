require 'database_cleaner/sequel'
require 'rspec/collection_matchers'
require 'rack/test'
require 'sequel/core'
require 'simplecov'

$LOAD_PATH.unshift File.expand_path('..', __dir__)

SimpleCov.start

ENV['APP_ENV'] = 'test'

require 'app'

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

  config.before(:suite) do
    CovidForm::Application.start(:persistence)

    db = CovidForm::Application[:db]

    Sequel.extension(:migration)

    Sequel::Migrator.run(db.sequel_db, 'app/db/migrations')

    DatabaseCleaner[:sequel].db = db.sequel_db
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      example.run
    end
  end

  config.include Rack::Test::Methods

  def app
    CovidForm::App
  end
end

module Rack
  class MockResponse
    def json
      body.empty? ? body : JSON.parse(body)
    end
  end
end

module JSONRequests
  def post_json(path, body = nil)
    header 'Content-Type', 'application/json'
    post(path, body && JSON.generate(body))
  end

  def patch_json(path, body = nil)
    header 'Content-Type', 'application/json'
    patch(path, body && JSON.generate(body))
  end
end
# rubocop:enable Style/MethodCallWithArgsParentheses

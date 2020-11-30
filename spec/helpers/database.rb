require 'sequel/core'
require 'database_cleaner/sequel'

RSpec.configure do |config|
  config.before(:suite) do
    CovidForm::Dependencies.start(:persistence)

    default_db_gateway = CovidForm::Dependencies[:db].default_gateway

    default_db_gateway.run_migrations(target: 0)
    default_db_gateway.run_migrations

    DatabaseCleaner[:sequel].db = default_db_gateway.connection
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    if example.metadata.fetch(:no_transaction, false)
      example.run

      DatabaseCleaner[:sequel].clean_with(:truncation)
    else
      DatabaseCleaner[:sequel].cleaning do
        example.run
      end
    end
  end
end

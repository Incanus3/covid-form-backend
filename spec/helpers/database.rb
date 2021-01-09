require 'sequel/core'
require 'database_cleaner/sequel'

def run_migrations(gateway, down: false, passwords: false)
  options = {}
  options[:target] = 0 if down

  if passwords
    options[:table] = 'password_migrations'
    orig_path       = gateway.migrator.path
    base, last      = File.split(orig_path)
    new_path        = File.join(base, last.sub('migrations', 'password_migrations'))

    gateway.migrator.instance_variable_set(:@path, new_path)
  end

  gateway.run_migrations(**options)

  gateway.migrator.instance_variable_set(:@path, orig_path) if passwords
end

RSpec.configure do |config|
  config.before(:suite) do
    CovidForm::Dependencies.start(:persistence)

    default_db_gateway = CovidForm::Dependencies[:db].default_gateway

    run_migrations(default_db_gateway, down: true, passwords: true)
    run_migrations(default_db_gateway, down: true)
    run_migrations(default_db_gateway)
    run_migrations(default_db_gateway, passwords: true)

    DatabaseCleaner[:sequel].db = default_db_gateway.connection
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation, except: ['password_migrations'])
  end

  config.around(:each) do |example|
    if example.metadata.fetch(:no_transaction, false)
      example.run

      DatabaseCleaner[:sequel].clean_with(:truncation, except: ['password_migrations'])
    else
      DatabaseCleaner[:sequel].cleaning do
        example.run
      end
    end
  end
end

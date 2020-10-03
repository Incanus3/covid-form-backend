require 'sequel/core'
require 'database_cleaner/sequel'

RSpec.configure do |config|
  config.before(:suite) do
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
end

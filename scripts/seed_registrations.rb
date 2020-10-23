#!/usr/bin/env ruby

APP_ROOT = File.expand_path('..', __dir__)

$LOAD_PATH.unshift APP_ROOT

require 'factory_bot'
require 'database_cleaner/sequel'
require 'spec/helpers/faker/cz_extensions'
require 'spec/feature/registration/helpers'

module CovidForm
  class Seeder
    include FactoryBot::Syntax::Methods
    include TestHelpers::Registration

    def self.with_db
      require 'app/dependencies'

      CovidForm::Dependencies.start(:persistence)

      include Import[:db]

      FactoryBot.find_definitions

      new
    end

    def clean_db
      default_db_gateway = CovidForm::Dependencies[:db].gateways[:default]

      DatabaseCleaner[:sequel].db = default_db_gateway.connection
      DatabaseCleaner[:sequel].clean_with(:truncation)
    end

    def seed_registrations(count = 100, max_days_forward: 7)
      create_many_clients_with_registrations(
        count, exam_overrides: { max_days_forward: max_days_forward }
      )
    end

    def seed_daily_overrides(count = 10, max_days_forward: 7, max_registration_limit: 10)
      attrs_list = Array.new(count) {
        {
          date:               Faker::Date.forward(days: max_days_forward),
          registration_limit: Random.rand(max_registration_limit),
        }
      }

      db.daily_overrides.create_many(attrs_list.uniq { |attrs| attrs[:date] })
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  seeder = CovidForm::Seeder.with_db

  seeder.clean_db
  seeder.populate_time_slots
  seeder.seed_registrations(30,   max_days_forward: 30)
  seeder.seed_daily_overrides(10, max_days_forward: 30)
end

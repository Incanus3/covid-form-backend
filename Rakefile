$LOAD_PATH.unshift '.'

require 'logger'
require 'app/db/database'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_task, args|
    require 'sequel/core'

    version = Integer(args[:version]) if args[:version]

    Sequel.extension(:migration)

    verbose = ENV['VERBOSE'] && !['false', 'no', 'n', '0'].include?(ENV['VERBOSE'].downcase)
    options = { logger: Logger.new($stderr, level: verbose ? :debug : :info) }

    CovidForm::Database.connect(**options) do |db|
      Sequel::Migrator.run(db, 'app/db/migrations', target: version)
    end
  end
end

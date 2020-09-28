$LOAD_PATH.unshift '.'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_task, args|
    require 'sequel/core'
    require 'app/application'

    version = Integer(args[:version]) if args[:version]

    Sequel.extension(:migration)

    CovidForm::Application.init(:persistence)

    CovidForm::Application[:db].connect do |db|
      Sequel::Migrator.run(db, 'app/db/migrations', target: version)
    end
  end
end

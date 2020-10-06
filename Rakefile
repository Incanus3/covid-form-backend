$LOAD_PATH.unshift '.'

require 'attr_extras'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_task, args|
    require 'sequel/core'
    require 'app/dependencies'

    version = Integer(args[:version]) if args[:version]

    Sequel.extension(:migration)

    CovidForm::Dependencies.init(:persistence)

    CovidForm::Dependencies[:db].connect do |database|
      Sequel::Migrator.run(database.sequel_db, 'app/persistence/migrations', target: version)
    end
  end
end

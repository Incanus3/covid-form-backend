APP_ROOT = File.expand_path(__dir__)

$LOAD_PATH.unshift(APP_ROOT)

require 'attr_extras'
require 'rom/sql/rake_task'
require 'app/dependencies'

CovidForm::Dependencies.start(:persistence)

namespace :db do
  desc 'set up database'
  task :setup do
    ROM::SQL::RakeSupport.env = CovidForm::Dependencies[:db]
  end
end

APP_ROOT = File.expand_path(__dir__)

$LOAD_PATH.unshift(APP_ROOT)

require 'attr_extras'
require 'bcrypt'
require 'rom/sql'
require 'rom/sql/rake_task'

module RakeSupportOverrides
  def run_migrations(options = {}) # rubocop:disable Style/OptionHash
    options[:table] = 'password_migrations' if ENV['is_password_migration'] == true.to_s

    super(options)
  end
end

module MigrationOverrides
  def create_migrator(migrator_option)
    if (ENV['is_password_migration'] == true.to_s
        && migrator_option.is_a?(Hash)
        && (path = migrator_option[:path]))
      base, last = File.split(path)

      migrator_option[:path] = File.join(base, last.sub('migrations', 'password_migrations'))
    end

    super(migrator_option)
  end
end

def get_db(prepend_overrides: false)
  require 'app/dependencies'

  if prepend_overrides
    ROM::SQL::Gateway.prepend(MigrationOverrides)
    ROM::SQL::RakeSupport.singleton_class.prepend(RakeSupportOverrides)
  end

  CovidForm::Dependencies.start(:persistence)
  CovidForm::Dependencies[:db]
end

namespace :db do
  desc 'set up database'
  task :setup do
    ROM::SQL::RakeSupport.env = get_db(prepend_overrides: true)
  end

  desc 'apply password migrations'
  task :migrate_passwords, [:version] do |_, args|
    ENV['is_password_migration'] = true.to_s
    Rake::Task['db:migrate'].invoke(*args)
  end

  desc 'create password migration'
  task :create_password_migration, [:name, :version] do |_, args|
    ENV['is_password_migration'] = true.to_s
    Rake::Task['db:create_migration'].invoke(*args)
  end
end

namespace :auth do
  desc 'create user'
  task :create_user, [:email] do |_, args|
    sequel_db = get_db.sequel_db
    email     = args[:email]
    print "enter password: "
    password  = STDIN.gets.chomp

    account_id = sequel_db[:accounts].insert(
      email:     email,
      status_id: 2, # verified
    )

    sequel_db[:account_password_hashes].insert(
      id:            account_id,
      password_hash: BCrypt::Password.create(password).to_s,
    )
  end
end

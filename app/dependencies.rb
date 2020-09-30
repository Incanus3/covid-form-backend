require 'dry/system/container'

module CovidForm
  class Dependencies < Dry::System::Container
    DEFAULT_DB_OPTIONS = {
      adapter:       ENV.fetch('DB_BACKEND',  'postgres'),
      host:          ENV.fetch('DB_HOST',     'localhost'),
      port:          ENV.fetch('DB_PORT',     '5432'),
      user:          ENV.fetch('DB_USER',     'covid'),
      password:      ENV.fetch('DB_PASSWORD', 'covid'),
      sql_log_level: :debug
    }.freeze

    configure do |config|
      # config.root = Pathname('./my/app')
    end

    verbose = ENV['VERBOSE'] && !['false', 'no', 'n', '0'].include?(ENV['VERBOSE'].downcase)

    register :env,    ENV.fetch('APP_ENV', :development).to_sym
    register :logger, Logger.new($stderr, level: verbose ? :debug : :info)

    boot(:persistence) do |container|
      init do
        require 'app/persistence/database'

        container.register(:db, Database.new(**DEFAULT_DB_OPTIONS.merge(
          database: container[:env] == :test ? 'covid_test' : 'covid',
          logger:   container[:logger],
        )))
      end

      start do
        container[:db].connect
      end

      stop do
        container[:db].disconnect
      end
    end
  end

  Import = Dry::AutoInject(Dependencies)
end

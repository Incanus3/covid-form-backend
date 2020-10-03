require 'dry/system/container'

module CovidForm
  class Dependencies < Dry::System::Container
    DEFAULT_DB_OPTIONS = {
      adapter:       ENV.fetch('DB_BACKEND',  'postgres'),
      host:          ENV.fetch('DB_HOST',     'localhost'),
      port:          ENV.fetch('DB_PORT',     '5432'),
      user:          ENV.fetch('DB_USER',     'covid'),
      password:      ENV.fetch('DB_PASSWORD', 'covid'),
      sql_log_level: :debug,
    }.freeze

    ENV_TO_OUTPUT_PROVIDER = {
      production:  -> { File.open(File.join(APP_ROOT, 'log', 'central.log'), 'a') },
      development: -> { $stderr },
      test:        -> { IO::NULL },
    }.freeze

    # TODO: split logging into several files in production
    def self.logger
      env     = resolve(:env) or raise 'env must be registered before calling logger'
      verbose = ENV['VERBOSE'] && !['false', 'no', 'n', '0'].include?(ENV['VERBOSE'].downcase)

      Logger.new(ENV_TO_OUTPUT_PROVIDER[env].call, level: verbose ? :debug : :info)
    end

    configure do |config|
      # config.root = Pathname('./my/app')
    end

    register :env,    ENV.fetch('APP_ENV', :development).to_sym
    register :logger, logger

    boot(:persistence) do |container|
      init do
        require 'lib/persistence/database'

        container.register(:db, Utils::Persistence::Database.new(**DEFAULT_DB_OPTIONS.merge(
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

    boot(:repository) do |container|
      start do
        use :persistence

        require 'app/persistence/repository'

        container.register(:repository, Persistence::Repository.new)
      end
    end
  end

  Import = Dry::AutoInject(Dependencies)
end

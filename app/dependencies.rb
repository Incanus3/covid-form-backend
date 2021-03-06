require 'dry/system/container'
require 'lib/env_vars'

module CovidForm
  class Dependencies < Dry::System::Container
    ENV_TO_OUTPUT_PROVIDER = {
      production:  -> { File.open(File.join(APP_ROOT, 'log', 'central.log'), 'a') },
      development: -> { $stderr },
      test:        -> { IO::NULL },
    }.freeze

    # TODO: split logging into several files in production
    def self.logger
      env     = resolve(:env) or raise 'env must be registered before calling logger'
      verbose = Utils::EnvVars.fetch_bool(:verbose)

      Logger.new(ENV_TO_OUTPUT_PROVIDER[env].call, level: verbose ? :debug : :info)
    end

    env = ENV.fetch('APP_ENV', :development).to_sym

    register :env,    env
    register :logger, logger

    boot(:persistence) do |container| # rubocop:disable Metrics/BlockLength
      default_db_options = {
        adapter:  ENV.fetch('DB_BACKEND',  'postgres'),
        host:     ENV.fetch('DB_HOST',     'localhost'),
        port:     ENV.fetch('DB_PORT',     '5432'),
        user:     ENV.fetch('DB_USER',     'covid'),
        password: ENV.fetch('DB_PASSWORD', 'covid'),
        database: ENV.fetch('DB_NAME',     'covid'),
      }.freeze

      init do
        require 'app/persistence/container'
      end

      start do
        options = default_db_options.merge({
          logger:        container[:logger],
          sql_log_level: :debug,
        })
        options[:database] += '_test' if container[:env] == :test

        db = CovidForm::Persistence::Container.new(options)
        db.start_connection_validator_with(timeout: 300)

        container.register(:db, db)
      end

      stop do
        container[:db].disconnect
      end
    end

    boot(:configuration) do |container|
      init do
        require 'app/configuration'
      end

      start do
        use :persistence

        container.register(:config, Configuration.new(container[:env], container[:db]))
      end
    end

    boot(:mail_sender) do |container|
      init do
        require 'lib/mail_sender'
      end

      start do
        Utils::MailSender.configure(container[:env], container[:logger])

        container.register(:mail_sender, Utils::MailSender.new(env: container[:env]))
      end
    end
  end

  Import = Dependencies.injector
end

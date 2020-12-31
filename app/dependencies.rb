require 'dry/system/container'
require 'lib/env_vars'

module CovidForm
  class Dependencies < Dry::System::Container
    DEFAULT_CONFIG_OPTIONS = {
      allow_registration_for_weekends:      false,
      enable_registration_deadline:         true,
      enable_time_slot_registraiton_limit:  true,
      daily_registration_limit:             Integer(ENV.fetch('DAILY_REGISTRATION_LIMIT',    250)),
      registration_deadline_offset_minutes: Integer(ENV.fetch('REGISTRATION_OFFSET_MINUTES', 300)),
    }.freeze

    DEFAULT_DB_OPTIONS = {
      adapter:  ENV.fetch('DB_BACKEND',  'postgres'),
      host:     ENV.fetch('DB_HOST',     'localhost'),
      port:     ENV.fetch('DB_PORT',     '5432'),
      user:     ENV.fetch('DB_USER',     'covid'),
      password: ENV.fetch('DB_PASSWORD', 'covid'),
      database: ENV.fetch('DB_NAME',     'covid'),
    }.freeze

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
    register :config, DEFAULT_CONFIG_OPTIONS

    register :auth,   {
      admin_password: ENV.fetch('ADMIN_PASSWORD') {
        if env == :production
          abort 'You must set the ADMIN_PASSWORD environment variable'
        else
          'admin'
        end
      },
      jwt_secret: ENV.fetch('JWT_SECRET') {
        if env == :production
          abort 'You must set the JWT_SECRET environment variable'
        else
          'secret'
        end
      },
    }

    boot(:persistence) do |container| # rubocop:disable Metrics/BlockLength
      init do
        require 'app/persistence/container'
      end

      start do
        options = DEFAULT_DB_OPTIONS.merge({
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

  Import = Dry::AutoInject(Dependencies)
end

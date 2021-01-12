require 'mail'
require_relative 'env_vars'

# to send through a gmail account, use
# SMTP_SERVER=smtp.gmail.com
# SMTP_PORT=465
# SMTP_USER=<username> (before @ sign)
# SMTP_PASSWORD=<password>
# SMTP_AUTH=login
# SMTP_TLS=true
# SMTP_SSL=false
# SMTP_STARTTLS=false
module Utils
  class MailSender
    # :nocov:
    # rubocop:disable Metrics/MethodLength
    def self.configure(env, logger)
      Mail.defaults do
        case env
        when :production
          if Utils::EnvVars.fetch_bool('DISABLE_EMAILS', default: false)
            delivery_method(:logger, logger: Logger.new(IO::NULL))
          else
            delivery_method(:smtp, Utils::MailSender.smtp_options_from_env)
          end
        when :development
          delivery_method :logger, logger: logger
        when :test
          delivery_method :test
        else
          raise "unknown environment #{env}"
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def self.smtp_options_from_env
      {
        address:              ENV.fetch('SMTP_SERVER',   'localhost'),
        port:                 ENV.fetch('SMTP_PORT',     25),
        authentication:       ENV.fetch('SMTP_AUTH',     nil),
        user_name:            ENV.fetch('SMTP_USER',     nil),
        password:             ENV.fetch('SMTP_PASSWORD', nil),
        tls:                  Utils::EnvVars.fetch_bool('SMTP_TLS',      default: false),
        ssl:                  Utils::EnvVars.fetch_bool('SMTP_SSL',      default: false),
        enable_starttls_auto: Utils::EnvVars.fetch_bool('SMTP_STARTTLS', default: false),
      }
    end
    # :nocov:

    def initialize(env:, default_from: nil)
      @env          = env
      @default_from = default_from || ENV.fetch('SMTP_DEFAULT_FROM', 'covid@test.cz')
    end

    def deliver(mail = nil, &block)
      if (mail && block) || (!mail && !block)
        raise 'you must either supply a Mail::Message object or a block, not both'
      end

      mail      ||= Mail.new(&block)
      mail.from ||= @default_from

      mail.deliver
    end
  end
end

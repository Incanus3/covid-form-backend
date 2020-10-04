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
    def self.configure(env, logger)
      Mail.defaults do
        case env
        when :production
          delivery_method(:smtp, Utils::MailSender.smtp_options_from_env)
        when :development
          delivery_method :logger, logger: logger
        when :test
          delivery_method :test
        else
          raise "unknown environment #{env}"
        end
      end
    end
    # :nocov:

    def self.smtp_options_from_env
      {
        address:              ENV.fetch('SMTP_SERVER'),
        port:                 ENV.fetch('SMTP_PORT', 587),
        authentication:       ENV.fetch('SMTP_AUTH', 'login'),
        user_name:            ENV.fetch('SMTP_USER'),
        password:             ENV.fetch('SMTP_PASSWORD'),
        tls:                  Utils::EnvVars.fetch_bool('SMTP_TLS',      default: true),
        ssl:                  Utils::EnvVars.fetch_bool('SMTP_SSL',      default: false),
        enable_starttls_auto: Utils::EnvVars.fetch_bool('SMTP_STARTTLS', default: false),
      }
    end

    def initialize(env:, default_from: nil)
      @env          = env
      @default_from = default_from || ENV.fetch('SMTP_DEFAULT_FROM', 'covid@test.cz')
    end

    def deliver(&block)
      mail = Mail.new(&block)
      mail.from ||= @default_from
      mail.deliver
    end
  end
end

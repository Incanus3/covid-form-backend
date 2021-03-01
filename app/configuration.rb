require 'ostruct'
require 'lib/env_vars'

module CovidForm
  class Configuration < OpenStruct
    include Utils::EnvVars

    def initialize(env, overrides = {})
      super(default_general_options(env).merge(auth: default_auth_options(env)).merge(overrides))
    end

    private def default_general_options(_env)
      {
        allow_registration_for_weekends:      false,
        enable_registration_deadline:         true,
        enable_time_slot_registraiton_limit:  true,
        daily_registration_limit:             Integer(ENV.fetch('DAILY_REGISTRATION_LIMIT',    250)),
        registration_deadline_offset_minutes: Integer(ENV.fetch('REGISTRATION_OFFSET_MINUTES', 300)),
      }.freeze
    end

    private def default_auth_options(env)
      {
        admin_password:                 fetch_required(env, :admin_password, dev_default: 'admin'),
        jwt_secret:                     fetch_required(env, :jwt_secret,     dev_default: 'secret'),
        hmac_secret:                    fetch_required(env, :hmac_secret,    dev_default: 'secret'),

        access_token_lifetime_minutes:  fetch(:token_lifetime_minutes, default: 5),
        refresh_token_lifetime_minutes: fetch(:token_lifetime_minutes, default: 24 * 60),
      }.freeze
    end
  end
end

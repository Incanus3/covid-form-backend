require 'ostruct'
require 'lib/env_vars'

module CovidForm
  class Configuration < OpenStruct
    include Utils::EnvVars

    attr_private :db, :env

    def initialize(env, db, overrides = {})
      @db  = db
      @env = env

      super(overrides)
    end

    def [](name)
      return super if table.has_key?(name.to_sym)

      begin
        db.settings.value_for!(name)
      rescue db.settings.class::NotFound
        default_options(env)[name.to_sym]
      end
    end

    def method_missing(name, *_args)
      return super if name.end_with?('=') || table.has_key?(name)

      begin
        db.settings.value_for!(name)
      rescue db.settings.class::NotFound
        default_options(env)[name]
      end
    end

    def respond_to_missing?(name, _include_all = false)
      super || default_options(env).respond_to?(name) || db.settings.key_exists?(name)
    end

    def to_h
      db_options = db.settings.with(auto_struct: false).all
        .map { [_1[:key].to_sym, _1[:value]] }.to_h

      default_options(env).to_h.merge(db_options).merge(table)
    end

    def to_a
      to_h.map { |key, value| { key: key, value: value } }
    end

    private

    def default_options(env)
      @_default_options ||= OpenStruct.new(
        default_general_options(env).merge(auth: default_auth_options(env)),
      )
    end

    def default_general_options(_env)
      fetch_int = ->(key, default) { Integer(ENV.fetch(key, default)) }

      {
        week_starts_on:                       1,
        open_registration_in_weeks:           1,
        close_registration_in_weeks:          1,
        allow_registration_for_weekends:      fetch_bool(
          'ALLOW_REGISTRATION_FOR_WEEKENDS', default: false
        ),
        enable_registration_deadline:         fetch_bool(
          'ENABLE_REGISTRATION_DEADLINE', default: true
        ),
        daily_registration_limit:             fetch_int.('DAILY_REGISTRATION_LIMIT',    250),
        registration_deadline_offset_minutes: fetch_int.('REGISTRATION_OFFSET_MINUTES', 300),
      }
    end

    def default_auth_options(env)
      {
        admin_password:                 fetch_required(env, :admin_password, dev_default: 'admin'),
        jwt_secret:                     fetch_required(env, :jwt_secret,     dev_default: 'secret'),
        hmac_secret:                    fetch_required(env, :hmac_secret,    dev_default: 'secret'),

        access_token_lifetime_minutes:  fetch(:token_lifetime_minutes, default: 5),
        refresh_token_lifetime_minutes: fetch(:token_lifetime_minutes, default: 24 * 60),
      }
    end
  end
end

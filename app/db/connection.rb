require 'sequel'

module CovidForm
  class DB
    DEFAULT_OPTIONS = {
      adapter:       ENV.fetch('DB_BACKEND',  'postgres'),
      host:          ENV.fetch('DB_HOST',     'localhost'),
      port:          ENV.fetch('DB_PORT',     '5432'),
      user:          ENV.fetch('DB_USER',     'covid'),
      password:      ENV.fetch('DB_PASSWORD', 'covid'),
      database:      ENV.fetch('DB_NAME',     'covid'),
      sql_log_level: :debug
    }.freeze

    def self.connect(**kwargs, &block)
      options = DEFAULT_OPTIONS.merge(kwargs)

      if block_given?
        Sequel.connect(**options, &block)
      else
        @_db ||= Sequel.connect(**kwargs)
      end
    end
  end
end

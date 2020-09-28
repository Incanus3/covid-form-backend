require 'attr_extras/explicit'
require 'forwardable'
require 'sequel'

module CovidForm
  class Database
    extend Forwardable
    extend AttrExtras.mixin

    DEFAULT_OPTIONS = {
      adapter:       ENV.fetch('DB_BACKEND',  'postgres'),
      host:          ENV.fetch('DB_HOST',     'localhost'),
      port:          ENV.fetch('DB_PORT',     '5432'),
      user:          ENV.fetch('DB_USER',     'covid'),
      password:      ENV.fetch('DB_PASSWORD', 'covid'),
      database:      ENV.fetch('DB_NAME',     'covid'),
      sql_log_level: :debug
    }.freeze

    @databases = {}

    def self.connect(**kwargs, &block)
      new(**kwargs).connect(&block)
    end

    def self.[](name)
      @databases[name.to_sym] or raise "Database #{name} not registered"
    end

    def self.[]=(name, database)
      @databases[name.to_sym] = database
    end

    attr_private :options
    def_delegators :sequel_db, :[], :transaction, :in_transaction?

    def initialize(sequel_db: nil, **kwargs)
      options = DEFAULT_OPTIONS.merge(kwargs)

      @options   = options
      @sequel_db = sequel_db
    end

    private def sequel_db
      @sequel_db or connect
    end

    def connect(&block)
      if block_given?
        Sequel.connect(**options, &block)
      else
        @sequel_db = Sequel.connect(**self.options)
      end
    end
  end
end

module Utils
  module Persistence
    class Container
      DEFAULT_CONFIG_OPTIONS = {}.freeze
      DEFAULT_REPO_OPTIONS   = {}.freeze

      # :nocov:
      def self.new(config_or_options)
        if config_or_options.is_a?(ROM::Configuration)
          config = config_or_options
        else
          options = self::DEFAULT_CONFIG_OPTIONS.merge(config_or_options)
          config  = Utils::Persistence.configure(**options)
        end

        super(ROM.container(config))
      end
      # :nocov:

      def self.register_repo(cls, as: nil)
        as ||= Utils::String.underscore(cls.name.split('::').last)

        define_method(as) { register_repo(cls) }
      end

      def initialize(rom_container)
        @repositories  = {}
        @rom_container = rom_container
      end

      def gateways
        self.rom_container.gateways
      end

      def default_gateway
        gateways[:default]
      end

      def options
        default_gateway.options
      end

      def start_connection_validator_with(timeout: 300, gateway: :default)
        sequel_db = rom_container.gateways[gateway].connection
        sequel_db.extension(:connection_validator)
        sequel_db.pool.connection_validation_timeout = timeout
      end

      private

      attr_reader :rom_container

      def register_repo(cls)
        @repositories[cls.name] ||= cls.new(self.rom_container, **self.class::DEFAULT_REPO_OPTIONS)
      end
    end
  end
end

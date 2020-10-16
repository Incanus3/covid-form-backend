require 'rom'
require 'lib/utils'
require 'lib/env_vars'

module Utils
  module Persistence
    # :nocov:
    def self.configure(uri = nil, logger: nil, auto_registration: nil, **connect_options)
      uri ||= "#{connect_options[:adapter]}://"

      ROM::Configuration.new(:sql, uri, **connect_options) do |config|
        config.gateways[:default].use_logger(logger) if logger

        if auto_registration
          config.auto_registration(auto_registration[:root_dir],
                                   **Utils::Hash.reject_keys(auto_registration, [:root_dir]))
        end
      end
    end
    # :nocov:
  end
end

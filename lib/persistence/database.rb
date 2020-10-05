require 'forwardable'
require 'sequel'

module Utils
  module Persistence
    class Database
      extend Forwardable

      attr_private :options
      def_delegators :sequel_db, :[], :table_exists?, :transaction, :in_transaction?

      def initialize(sequel_db: nil, **options)
        options[:keep_reference] ||= false

        @options   = options
        @sequel_db = sequel_db
      end

      def sequel_db
        @sequel_db or connect
      end

      def connect(&block)
        if @sequel_db
          if block_given?
            block.call(@sequel_db)
          else
            @sequel_db
          end
        else
          connect!(&block)
        end
      end

      def connect!(&block)
        if block_given?
          Sequel.connect(**self.options, &block)
        else
          @sequel_db = Sequel.connect(**self.options)
        end
      end
    end
  end
end

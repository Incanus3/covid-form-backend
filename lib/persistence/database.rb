require 'forwardable'
require 'sequel'

module Utils
  module Persistence
    class Database
      extend Forwardable

      attr_reader :options

      def_delegators(:sequel_db,
                     :disconnect,   :[],
                     :create_table, :table_exists?,
                     :transaction,  :in_transaction?)

      def initialize(sequel_db: nil, **options)
        options[:keep_reference] ||= false

        @options   = options
        @sequel_db = sequel_db
      end

      def sequel_db
        connect unless connected?

        @sequel_db
      end

      def connect(&block)
        if connected?
          if block_given?
            yield self
          else
            self
          end
        else
          connect!(&block)
        end
      end

      def connect!
        if block_given?
          Sequel.connect(**self.options) do |sequel_db|
            yield self.class.new(sequel_db: sequel_db, **self.options)
          end
        else
          @sequel_db = Sequel.connect(**self.options)

          self
        end
      end

      def connected?
        !!@sequel_db
      end

      def backend_type
        sequel_db.database_type
      end
    end
  end
end

require 'lib/transformations'
require 'sequel/model'

module Utils
  module Persistence
    class MissingTable < RuntimeError
      def initialize(database, table_name)
        super("database '#{database.options[:database]}' has no table '#{table_name}'")
      end
    end

    class InvalidConstructor < RuntimeError
      def initialize
        super('constructor must respond to #call or #new')
      end
    end

    class Repository
      class << self
        private

        def register_relation(name, **kwargs)
          define_method(name) { get_relation(name, **kwargs) }
        end
      end

      private

      attr_implement :database # must return a Utils::Persistence::Database instance
      attr_accessor :relations

      def get_relation(name, table_name: name, constructor: nil, dataset_module: nil)
        self.relations ||= {}

        table_name = table_name.to_sym
        class_name = Utils::String.camelize(name)

        return self.relations[name] if self.relations.has_key?(name)

        raise MissingTable.new(database, table_name) unless database.table_exists?(table_name)

        # TODO: so as not to leak abstraction, this will need to wrap the new model subclass in a
        # Ralation instance, that will delegate to it and translate Sequel exceptions to custom ones

        self.relations[name] = create_model(
          class_name:     class_name,
          relation_name:  name,
          dataset:        dataset_for(database, table_name, constructor),
          dataset_module: dataset_module,
        )
      end

      # rubocop:disable Metrics/MethodLength
      def create_model(class_name:, relation_name:, dataset:, dataset_module:)
        Class.new(Sequel::Model) do
          @relation_name       = relation_name
          @relation_class_name = class_name

          def self.name
            @relation_class_name
          end

          def self.to_s
            name
          end

          def self.inspect
            "#<Relation #{@relation_name}>"
          end

          def self.create(...)
            dataset.row_proc.call(dataset.returning.insert(...).first)
          end

          def self.set_dataset_row_proc(dataset) # rubocop:disable Naming/AccessorMethodName
            dataset # don't reset dataset row proc to model constructor
          end

          self.dataset = dataset # must be called after redefining set_dataset_row_proc
          self.dataset_module(dataset_module) if dataset_module
        end
      end
      # rubocop:enable Metrics/MethodLength

      def dataset_for(database, table_name, constructor)
        row_proc = constructor && to_row_proc(constructor)

        if row_proc
          database[table_name].with_row_proc(row_proc)
        else
          database[table_name].naked
        end
      end

      def to_row_proc(constructor)
        if constructor.respond_to?(:call)
          constructor
        elsif constructor.respond_to?(:new)
          constructor.method(:new)
        else
          raise InvalidConstructor
        end
      end
    end
  end
end

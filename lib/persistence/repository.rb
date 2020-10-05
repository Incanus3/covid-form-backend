require 'lib/transformations'
require 'sequel/model'

module Utils
  module Persistence
    class Repository
      class << self
        private

        def register_relation(name, **kwargs)
          define_method(name) { get_relation(name, **kwargs) }
        end
      end

      private

      attr_implement :database # must return a Utils::Persistence::Database instance

      def get_relation(name, constructor: nil, dataset_module: nil)
        class_name = Utils::String.camelize(name)

        return self.class.const_get(class_name) if self.class.const_defined?(class_name)

        raise "database has no table #{name}" unless database.table_exists?(name)

        # TODO: so as not to leak abstraction, this will need to wrap the new model subclass in a
        # Ralation instance, that will delegate to it and translate Sequel exceptions to custom ones

        self.class.const_set(class_name, create_model(
          db_name:        name,
          row_proc:       constructor && to_row_proc(constructor),
          dataset_module: dataset_module,
        ))
      end

      def create_model(db_name:, row_proc:, dataset_module:)
        database = self.database

        Class.new(Sequel::Model) do
          def self.create(...)
            dataset.row_proc.call(dataset.returning.insert(...).first)
          end

          self.dataset_module(dataset_module) if dataset_module

          if row_proc
            def self.set_dataset_row_proc(dataset) # rubocop:disable Naming/AccessorMethodName
              dataset # don't reset dataset row proc to model constructor
            end

            self.dataset = database[db_name].with_row_proc(row_proc)
          else
            self.dataset = database[db_name]
          end
        end
      end

      def to_row_proc(constructor)
        if constructor.respond_to?(:call)
          constructor
        elsif constructor.respond_to?(:new)
          constructor.method(:new)
        else
          raise 'constructor must respond to #call or #new'
        end
      end
    end
  end
end

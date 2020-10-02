require 'sequel/model'

module Utils
  module Persistence
    # subclass must provide db method returning a Database
    class Repository
      private

      def get_relation(name, constructor: nil, dataset_module: nil)
        class_name = name.to_s.camelize

        return self.class.const_get(class_name) if self.class.const_defined?(class_name)

        raise "database has no table #{name}" unless db.table_exists?(name)

        self.class.const_set(class_name, create_model(
          db_name:        name,
          row_proc:       constructor && to_row_proc(constructor),
          dataset_module: dataset_module,
        ))
      end

      def create_model(db_name:, row_proc:, dataset_module:)
        Class.new(Sequel::Model) do
          self.dataset_module(dataset_module) if dataset_module

          if row_proc
            def self.set_dataset_row_proc(dataset) # rubocop:disable Naming/AccessorMethodName
              dataset # don't reset dataset row proc to model constructor
            end

            self.dataset = db[db_name].with_row_proc(row_proc)
          else
            self.dataset = db[db_name]
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

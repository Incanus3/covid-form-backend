require 'rom/repository'

module Utils
  module Persistence
    class Repository < ROM::Repository::Root
      commands :create, update: :by_pk, delete: :by_pk

      def all
        root.to_a
      end

      def count_all
        root.count
      end

      def first
        root.first
      end

      def find(pk)
        root.by_pk(pk).one!
      end

      def create_many(tuples)
        root.command(:create, result: :many).call(tuples)
      end

      private

      def default_gateway
        container.gateways[:default]
      end
    end
  end
end

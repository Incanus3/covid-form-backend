require 'rom/repository'

module Utils
  module Persistence
    class Repository < ROM::Repository::Root
      commands :create, update: :by_pk, delete: :by_pk

      def model
        root.mapper.model
      end

      def all
        root.to_a
      end

      def all_by_id
        root.order(:id).to_a
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

      def lock_by_id(id)
        root.by_pk(id).lock
      end

      private

      def default_gateway
        container.gateways[:default]
      end
    end
  end
end

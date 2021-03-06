require 'rom/repository'

module Utils
  module Persistence
    class Repository < ROM::Repository::Root
      NotFound = ::Class.new(RuntimeError)

      commands :create, update: :by_pk, delete: :by_pk

      def model
        root.mapper.model
      end

      def primary_key
        root.primary_key
      end

      def all
        root.to_a
      end

      def all_ids
        root.pluck(:id)
      end

      def all_by_id
        root.order(:id).to_a
      end

      def all_by_id_with(assocs)
        root.combine(*assocs).order(:id).to_a
      end

      def count_all
        root.count
      end

      def first
        root.first
      end

      def find(pk)
        root.by_pk(pk).one
      end

      def find!(pk)
        root.by_pk(pk).one!
      rescue ROM::TupleCountMismatchError
        raise NotFound
      end

      def create_many(tuples)
        root.command(:create, result: :many).call(tuples)
      end

      def lock_by_id(id)
        root.by_pk(id).lock
      end

      def delete_by_id(id)
        root.by_pk(id).delete
      end

      private

      def default_gateway
        container.gateways[:default]
      end
    end
  end
end

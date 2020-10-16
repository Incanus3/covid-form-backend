require 'rom/repository'

module Utils
  module Persistence
    class Repository < ROM::Repository::Root
      commands :create, update: :by_pk, delete: :by_pk

      def find(pk)
        root.by_pk(pk).one!
      end

      def create_many(tuples)
        root.command(:create, result: :many).call(tuples)
      end
    end
  end
end

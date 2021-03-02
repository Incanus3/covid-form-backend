require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class Settings < Utils::Persistence::Relation
        schema(:settings) do
          attribute :key,   Types::String.meta(primary_key: true)
          attribute :value, Types::PG::JSONB

          # primary_key :key
        end
      end
    end
  end
end

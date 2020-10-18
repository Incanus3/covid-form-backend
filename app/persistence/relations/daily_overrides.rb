require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class DailyOverrides < Utils::Persistence::Relation
        schema(:daily_overrides) do
          attribute :id,                 Types::Integer
          attribute :date,               Types::Date
          attribute :registration_limit, Types::Integer

          primary_key :id
        end

        def by_date(date)
          where(date: date)
        end
      end
    end
  end
end

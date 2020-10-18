require 'lib/persistence/repository'

module CovidForm
  module Persistence
    module Repositories
      class DailyOverrides < Utils::Persistence::Repository[:daily_overrides]
        def for_date(date)
          daily_overrides.by_date(date).one
        end
      end
    end
  end
end

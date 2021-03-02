require 'lib/persistence/repository'

module CovidForm
  module Persistence
    module Repositories
      class Settings < Utils::Persistence::Repository[:settings]
        def value_for(key)
          find(key.to_s)&.value
        end

        def value_for!(key)
          find!(key.to_s).value
        end

        def key_exists?(key)
          root.by_pk(key.to_s).exist?
        end
      end
    end
  end
end

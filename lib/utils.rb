require 'dry/inflector'
require 'dry/transformer'

module Utils
  String = Dry::Inflector.new.freeze
  Array  = Dry::Transformer::ArrayTransformations
  Hash   = Dry::Transformer::HashTransformations

  module Date
    module_function

    def tomorrow
      ::Date.today + 1
    end
  end

  module Time
    module_function

    def today_at(hour, minute, second = 0)
      today = ::Date.today

      ::Time.local(today.year, today.month, today.day, hour, minute, second)
    end

    def format(time)
      I18n.l(time, format: :time_only).delete_prefix('0')
    end
  end

  module Transformations
    extend Dry::Transformer::Registry

    import Dry::Transformer::Coercions
    import Dry::Transformer::ArrayTransformations
    import Dry::Transformer::HashTransformations
    # import Dry::Transformer::ClassTransformations
    # import Dry::Transformer::ProcTransformations
    # import Dry::Transformer::Conditional
    # import Dry::Transformer::Recursion
  end

  T = Transformations
end

require 'dry/inflector'
require 'dry/transformer'

module Utils
  String = Dry::Inflector.new.freeze
  Array  = Dry::Transformer::ArrayTransformations
  Hash   = Dry::Transformer::HashTransformations

  module Class
    module_function

    def name(cls)
      cls.name.split('::').last
    end
  end

  module Date
    COMMON_YEAR_DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

    module_function

    def days_in_month(month:, year: ::Time.now.year)
      return 29 if month == 2 && ::Date.leap?(year)

      COMMON_YEAR_DAYS_IN_MONTH[month - 1]
    end

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

    def format(time, remove_leading_zeros: true)
      time_str = I18n.l(time, format: :time_only)
      time_str.delete_prefix!('0') if remove_leading_zeros
      time_str
    end
  end

  module Number
    module_function

    def divisible_by?(number, divisor)
      (number % divisor).zero?
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

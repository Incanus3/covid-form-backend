module Utils
  module EnvVars
    module_function

    FALSY_VALUES = %w[false f no n 0].freeze

    def fetch_bool(name, default: false, upcase: true)
      name  = name.to_s
      name  = name.upcase if upcase
      value = ENV[name]

      value && !FALSY_VALUES.include?(value.downcase) || default
    end
  end
end

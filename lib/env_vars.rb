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

    def fetch_required(env, name, dev_default:, upcase: true)
      name  = name.to_s
      name  = name.upcase if upcase

      ENV.fetch(name) {
        if env == :production
          abort "You must set the #{name} environment variable"
        else
          dev_default
        end
      }
    end
  end
end

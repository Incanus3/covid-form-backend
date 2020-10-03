require 'factory_bot'
require 'faker'

module Faker
  class Base
    def self.random_bool
      [true, false].sample
    end
  end

  class CZIDNumber < IDNumber
    def self.valid
      "#{Faker::Date.birthday.strftime('%y%m%d')} #{Faker::Number.number(digits: 4)}"
    end
  end

  class CEPhoneNumber < PhoneNumber
    class << self
      alias bare_phone_number phone_number

      def country_code
        country_code   = fetch('country_code')
        cc_with_prefix = random_bool ? "+#{country_code}" : "00#{country_code}"

        random_bool ? cc_with_prefix : "(#{cc_with_prefix})"
      end

      def phone_number_with_country_code
        "#{country_code} #{bare_phone_number}"
      end

      def phone_number
        random_bool ? bare_phone_number : phone_number_with_country_code
      end
    end
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  Faker::Config.locale = 'cz'

  # TODO: do this relative to __dir__
  I18n.load_path << Dir["#{File.join(APP_ROOT, 'config', 'locales')}/*.yml"]

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

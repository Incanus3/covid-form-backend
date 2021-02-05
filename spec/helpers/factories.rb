require 'factory_bot'
require 'faker'
require_relative 'faker/cz_extensions'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  Faker::Config.locale = 'cz'

  I18n.load_path << Dir["#{File.join(APP_ROOT, 'config', 'locales')}/*.yml"]
  I18n.default_locale = :en

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

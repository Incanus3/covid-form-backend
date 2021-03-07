require 'app/dependencies'

RSpec.configure do |config|
  config.before(:suite) do
    CovidForm::Dependencies.start(:configuration)
  end
end

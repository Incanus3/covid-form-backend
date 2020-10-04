APP_ROOT = File.expand_path('..', __dir__)
ENV['APP_ENV'] = 'test'

$LOAD_PATH.unshift(APP_ROOT)

require_relative 'helpers/base'
require_relative 'helpers/database'
require_relative 'helpers/factories'
require_relative 'helpers/mail'
require_relative 'helpers/simplecov'
require_relative 'helpers/web'

RSpec.configure do
  def app
    CovidForm::Web::App
  end
end

SimpleCov.start

require 'app/web/app'

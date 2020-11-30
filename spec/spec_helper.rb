APP_ROOT = File.expand_path('..', __dir__) unless defined?(APP_ROOT)
ENV['APP_ENV'] = 'test'

$LOAD_PATH.unshift(APP_ROOT)

require 'attr_extras'
require 'timecop'
require_relative 'helpers/base'
require_relative 'helpers/configuration'
require_relative 'helpers/database'
require_relative 'helpers/factories'
require_relative 'helpers/mail'
require_relative 'helpers/simplecov'
require_relative 'helpers/web'

SimpleCov.start

require 'lib/utils'
require 'app/web/app'

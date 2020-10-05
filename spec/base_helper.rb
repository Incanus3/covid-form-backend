APP_ROOT = File.expand_path('..', __dir__) unless defined?(APP_ROOT)
ENV['APP_ENV'] = 'test'

$LOAD_PATH.unshift(APP_ROOT)

require 'attr_extras'
require_relative 'helpers/base'
require_relative 'helpers/simplecov'

SimpleCov.start

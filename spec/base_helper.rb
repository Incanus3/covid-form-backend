APP_ROOT = File.expand_path('..', __dir__)
ENV['APP_ENV'] = 'test'

$LOAD_PATH.unshift(APP_ROOT)

require_relative 'helpers/base'
require_relative 'helpers/simplecov'

SimpleCov.start

require 'i18n'

$LOAD_PATH.unshift '.'

APP_ROOT = __dir__

I18n.load_path << Dir["#{File.join(APP_ROOT, 'config', 'locales')}/*.yml"]
I18n.default_locale = :cz

require 'app/web/app'

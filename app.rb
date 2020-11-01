require 'attr_extras'
require 'i18n'

APP_ROOT = __dir__

$LOAD_PATH.unshift APP_ROOT

I18n.load_path << Dir["#{File.join(APP_ROOT, 'config', 'locales')}/*.yml"]
I18n.default_locale = :cz

require 'app/web/app'

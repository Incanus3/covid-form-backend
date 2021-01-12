require 'rack/cors'
require_relative './app'

use Rack::Cors do
  allow do
    origins(
      'localhost:3000', '127.0.0.1:3000',
      'https://covid-form.production-e.asrv.cz',
      'https://covid-form.production1-tth.asrv.cz',
      'https://covid-form.production2-tth.asrv.cz',
      'https://vaccination-form.production-e.asrv.cz',
      'https://vaccination-form.production1-tth.asrv.cz',
      'https://vaccination-form.production2-tth.asrv.cz',
    )

    resource '*', headers: :any, methods: %i[get post delete put patch options head]
  end
end

run CovidForm::Web::App.freeze.app

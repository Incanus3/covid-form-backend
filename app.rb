$LOAD_PATH.unshift './lib'

require 'roda'
require 'dry-schema'

module CovidForm
  class App < Roda
    plugin :halt
    plugin :all_verbs
    plugin :not_allowed
    plugin :symbol_status
    plugin :json
    plugin :json_parser

    route do |r|
      r.root do # GET /
        '<p>tady bude seznam rout</p>'
      end

      r.is 'register' do
        r.post do
          { result: 'OK' }
        end
      end
    end
  end
end

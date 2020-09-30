require 'attr_extras'
require 'roda'

require 'app/dependencies'
require 'app/services/registration'
require 'app/web/validation'
require 'app/web/serialization'

module CovidForm
  module Web
    class App < Roda
      plugin :halt
      plugin :all_verbs
      plugin :not_allowed
      plugin :symbol_status
      plugin :json
      plugin :json_parser

      include Validation
      include Serialization

      # Dependencies.start(:persistence) # TODO: stop persistence on exit
      Dependencies.start(:repository)

      route do |r| # rubocop:disable Metrics/BlockLength
        r.root do # GET /
          '<p>tady bude seznam rout</p>'
        end

        r.is 'register' do
          r.post do # POST /register
            validation_result = RegistrationContract.new.call(request.params)

            if validation_result.success?
              result     = Registration.perform(validation_result.to_h)
              serializer = RegistrationResultSerializer
            else
              result     = validation_result.errors
              serializer = ValidationErrorsSerializer
            end

            response.status, body = serializer.serialize(result)

            body
          end
        end
      end
    end
  end
end

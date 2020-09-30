require 'attr_extras'
require 'roda'

require 'app/dependencies'
require 'app/services/registration'
require 'app/web/serializers'
require 'app/web/validation/schemas'

module CovidForm
  module Web
    class App < Roda
      plugin :halt
      plugin :all_verbs
      plugin :not_allowed
      plugin :symbol_status
      plugin :json
      plugin :json_parser

      Dependencies.start(:persistence) # TODO: stop persistence on exit

      route do |r| # rubocop:disable Metrics/BlockLength
        r.root do # GET /
          '<p>tady bude seznam rout</p>'
        end

        r.is 'register' do
          r.post do # POST /register
            # TODO: use dry-validations to add advanced rules
            validation_result = REGISTRATION_SCHEMA.call(request.params)

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

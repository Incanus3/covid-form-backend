require 'attr_extras'
require 'roda'

require 'app/dependencies'
require 'app/services/export'
require 'app/services/registration'
require 'app/web/validation'
require 'app/web/serialization'
require 'app/web/services/authentication'

module CovidForm
  module Web
    class App < Roda
      plugin :all_verbs
      plugin :halt
      plugin :json
      plugin :json_parser
      plugin :not_allowed
      plugin :request_headers
      plugin :symbol_status

      include Validation
      include Serialization

      Dependencies.start(:repository) # TODO: stop persistence on exit
      Dependencies.start(:mail_sender)

      def authenticate!(request)
        result = Authentication.perform(request)

        return unless result.failure?

        status, body = AuthenticationFailureSerializer.serialize(result)
        request.halt(status, body)
      end

      route do |r| # rubocop:disable Metrics/BlockLength
        r.root do # GET /
          <<~TXT
            <h1>Seznam rout</h1>
            <ul>
              <li>POST /register</li>
            </ul>
          TXT
        end

        r.is 'register' do
          r.post do # POST /register
            validation_result = RegistrationContract.new.call(request.params)

            if validation_result.success?
              result     = Services::Registration.perform(validation_result.to_h)
              serializer = RegistrationResultSerializer
            else
              result     = validation_result.errors
              serializer = ValidationErrorsSerializer
            end

            response.status, body = serializer.serialize(result)

            body
          end
        end

        r.is 'export' do
          r.get do
            authenticate!(request)

            result = Services::Export.perform

            response.status, body = ExportResultSerializer.serialize(result)

            body
          end
        end
      end
    end
  end
end

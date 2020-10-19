require 'attr_extras'
require 'roda'

require 'app/dependencies'
require 'app/services/export'
require 'app/services/registration'
require 'app/web/validation'
require 'app/web/serialization'
require 'app/web/services/authentication'
require 'app/web/services/crud'

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

      Dependencies.start(:persistence) # TODO: stop persistence on exit
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
              client_data, exam_data = validation_result.to_h.values_at(:client, :exam)

              result     = Services::Registration.new(client_data: client_data,
                                                      exam_data:   exam_data).perform
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

            validation_result = ExportContract.new.call(request.params)

            if validation_result.success?
              result     = Services::Export.perform(validation_result.to_h)
              serializer = ExportResultSerializer
            else
              result     = validation_result.errors
              serializer = ValidationErrorsSerializer
            end

            response.status, body = serializer.serialize(result)

            body
          end
        end

        r.on 'crud' do
          r.is 'time_slots' do
            r.get do
              time_slots = CRUD::TimeSlots.all_with_time_ranges

              response.status, body = TimeSlotSerializer.serialize_many(time_slots)

              body
            end
          end
        end
      end
    end
  end
end

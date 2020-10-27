require 'attr_extras'
require 'roda'

require 'app/dependencies'
require 'app/services/export'
require 'app/services/capacity'
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

      Dependencies.start(:persistence) # TODO: stop persistence on exit
      Dependencies.start(:mail_sender)

      def authenticate!(request)
        result = Authentication.new(request: request).perform

        return unless result.failure?

        status, body = Serializers::AuthenticationFailure.serialize(result)
        request.halt(status, body)
      end

      route do |r| # rubocop:disable Metrics/BlockLength
        r.root do # GET /
          <<~TXT
            <h1>Seznam rout</h1>
            <ul>
              <li>POST /register</li>
              <li>GET /export</li>
              <li>GET /crud/time_slots</li>
              <li>GET /capacity/full_dates</li>
            </ul>
          TXT
        end

        r.is 'register' do
          r.post do # POST /register
            validation_result = Validation::Contracts::Registration.new.call(request.params)

            if validation_result.success?
              client_data, exam_data = validation_result.to_h.values_at(:client, :exam)

              result     = Services::Registration.new(client_data: client_data,
                                                      exam_data:   exam_data).perform
              serializer = Serializers::RegistrationResult
            else
              result     = validation_result.errors
              serializer = Serializers::ValidationErrors
            end

            response.status, body = serializer.serialize(result)

            body
          end
        end

        r.on 'capacity' do
          r.is 'full_dates' do
            r.get do # GET /capacity/full_dates
              validation_result = Validation::Contracts::FullDates.new.call(request.params)

              if validation_result.success?
                result     = Services::Capacity.new(validation_result.to_h).full_dates
                serializer = Serializers::FullDatesResult
              else
                result     = validation_result.errors
                serializer = Serializers::ValidationErrors
              end

              response.status, body = serializer.serialize(result)

              body
            end
          end
        end

        r.is 'export' do
          r.get do # GET /export
            authenticate!(request)

            validation_result = Validation::Contracts::Export.new.call(request.params)

            if validation_result.success?
              result     = Services::Export.new(validation_result.to_h).perform
              serializer = Serializers::ExportResult
            else
              result     = validation_result.errors
              serializer = Serializers::ValidationErrors
            end

            response.status, body = serializer.serialize(result)

            body
          end
        end

        r.on 'crud' do
          r.is 'time_slots' do
            r.get do # GET /crud/time_slots
              time_slots = CRUD::TimeSlots.new.all_with_time_ranges

              response.status, body = Serializers::TimeSlot.serialize_many(time_slots)

              body
            end
          end
        end
      end
    end
  end
end

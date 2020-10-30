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

      def action(request, validation_contract:, result_serializer:)
        validation_result = validation_contract.new.call(request.params)

        if validation_result.success?
          result     = yield validation_result.to_h
          serializer = result_serializer
        else
          result     = validation_result.errors
          serializer = Serializers::ValidationErrors
        end

        response.status, body = serializer.serialize(result)

        body
      end

      route do |r| # rubocop:disable Metrics/BlockLength
        r.root do # GET /
          <<~HTML
            <h1>Seznam rout</h1>
            <ul>
              <li>POST /register</li>
              <li>GET /export</li>
              <li>GET /crud/time_slots</li>
              <li>GET /capacity/full_dates</li>
            </ul>
          HTML
        end

        r.is 'register' do
          r.post do # POST /register
            action(
              request,
              validation_contract: Validation::Contracts::Registration,
              result_serializer:   Serializers::RegistrationResult,
            ) do |params|
              Services::Registration.new(client_data: params[:client],
                                         exam_data:   params[:exam]).perform
            end
          end
        end

        r.on 'capacity' do
          r.is 'full_dates' do
            r.get do # GET /capacity/full_dates
              action(
                request,
                validation_contract: Validation::Contracts::FullDates,
                result_serializer:   Serializers::FullDatesResult,
              ) do |params|
                Services::Capacity.new(params).full_dates
              end
            end
          end
        end

        r.is 'export' do
          r.get do # GET /export
            authenticate!(request)

            action(
              request,
              validation_contract: Validation::Contracts::Export,
              result_serializer:   Serializers::ExportResult,
            ) do |params|
              Services::Export.new(params).perform
            end
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

require 'roda'

require 'app/dependencies'
require 'app/services/export'
require 'app/services/capacity'
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

      Dependencies.start(:persistence) # TODO: stop persistence on exit
      Dependencies.start(:mail_sender)

      def authenticate!(request)
        result = Authentication.new(request: request).perform

        return unless result.failure?

        status, body = Serializers::AuthenticationFailure.serialize(result)
        request.halt(status, body)
      end

      def action(request, validation_contract:, result_serializer:, multiple_results: false)
        validation_result = validation_contract.new.call(request.params)

        if validation_result.success?
          result            = yield validation_result.to_h
          serializer        = result_serializer
          serializer_method = multiple_results ? :serialize_many : :serialize
        else
          result            = validation_result.errors
          serializer        = Serializers::ValidationErrors
          serializer_method = :serialize
        end

        response.status, body, headers = serializer.public_send(serializer_method, result)

        response.headers.merge!(headers)

        body
      end

      # rubocop:disable Metrics/BlockLength
      route do |r|
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
                Services::Capacity.new.full_dates_between(**params)
              end
            end
          end

          r.is 'available_time_slots' do
            r.get do # GET /crud/time_slots
              action(
                request,
                validation_contract: Validation::Contracts::TimeSlots,
                result_serializer:   Serializers::TimeSlot,
                multiple_results:    true,
              ) do |params|
                Services::Capacity.new
                  .available_time_slots_for(*params.values_at(:date, :exam_type))
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
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end

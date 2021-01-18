require_relative 'serialization'

module CovidForm
  module Web
    class AppBase < Roda
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze
      JSON_CONTENT_TYPE   = 'application/json'.freeze

      plugin :all_verbs
      plugin :error_handler
      plugin :halt
      plugin :json_parser
      plugin :not_allowed
      plugin :request_headers
      plugin :status_handler

      # rubocop:disable Style/MethodCallWithArgsParentheses
      def self.enable_rodauth(options)
        plugin :rodauth, json: :only do
          enable :login, :jwt, :jwt_refresh

          prefix '/auth'
          login_param 'email'
          jwt_refresh_route 'refresh_token'

          jwt_secret  options[:jwt_secret]
          hmac_secret options[:hmac_secret]

          json_response_error_status      401
          expired_jwt_access_token_status 401

          set_deadline_values?                         true
          allow_refresh_with_expired_jwt_access_token? true

          jwt_access_token_period                      options[:access_token_lifetime_minutes] * 60
          jwt_refresh_token_deadline_interval minutes: options[:refresh_token_lifetime_minutes]
        end
      end
      # rubocop:enable Style/MethodCallWithArgsParentheses

      def respond_with(serializer_response)
        # :nocov:
        serializer_response in [status, body, headers]
        # :nocov:

        if serializer_response.json?
          headers = { CONTENT_TYPE_HEADER => JSON_CONTENT_TYPE }.merge(headers)
          body    = body.to_json
        end

        request.halt([Rack::Utils.status_code(status), headers, [body]])
      end

      def action(
        validation_contract:, result_serializer:,
        multiple_results: false, serializer_options: {}
      )
        validation_result = validation_contract.new.call(request.params)

        if validation_result.success?
          result            = yield validation_result.to_h
          serializer        = result_serializer
          serializer_method = multiple_results ? :serialize_many : :serialize

          respond_with serializer.public_send(serializer_method, result, **serializer_options)
        else
          respond_with Serializers::ValidationErrors.serialize(validation_result.errors)
        end
      end

      def crud_actions(service:, validation_contract:)
        request.is do
          get_all_action(service: service)
          create_action( service: service, validation_contract: validation_contract)
        end

        request.is Integer do |id|
          update_action(id, service: service, validation_contract: validation_contract)
        end
      end

      def get_all_action(service:)
        request.get do
          # TODO: validate params

          service_inst = service.new
          result =
            if (assocs = request.params['with'])
              service_inst.all_with(assocs)
            else
              service_inst.all
            end

          respond_with Serializers::CRUDServiceResult.serialize(service_inst, result)
        end
      end

      def create_action(service:, validation_contract:)
        request.post do
          validation_result = validation_contract.new.call(request.params)

          if validation_result.success?
            service_inst = service.new
            result       = service_inst.create(validation_result.to_h)

            respond_with Serializers::CRUDServiceResult.serialize(service_inst, result)
          else
            respond_with Serializers::ValidationErrors.serialize(validation_result.errors)
          end
        end
      end

      def update_action(id, service:, validation_contract:)
        request.put do
          validation_result = validation_contract.new.call(request.params)

          if validation_result.success?
            service_inst = service.new
            result       = service_inst.update(id, validation_result.to_h)

            respond_with Serializers::CRUDServiceResult.serialize(service_inst, result)
          else
            respond_with Serializers::ValidationErrors.serialize(validation_result.errors)
          end
        end
      end
    end
  end
end

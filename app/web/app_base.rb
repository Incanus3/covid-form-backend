require_relative 'serialization'
require_relative 'services/authentication'

module CovidForm
  module Web
    class AppBase < Roda
      plugin :all_verbs
      plugin :halt
      plugin :json
      plugin :json_parser
      plugin :not_allowed
      plugin :request_headers
      plugin :symbol_status

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
    end
  end
end

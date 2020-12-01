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

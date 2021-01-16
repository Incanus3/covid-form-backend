require 'dry/core/class_attributes'

module Utils
  module Web
    class Response
      extend Dry::Core::ClassAttributes

      defines :status,    type: ::Symbol
      defines :base_body, type: ::Hash

      status :override_me
      base_body({}.freeze)

      attr_value_initialize :status, :body, :headers

      def self.with(fields)
        new(status, base_body.merge(fields.to_h), {})
      end

      # this may not be needed if we define destructuring
      def deconstruct
        [status, body, headers]
      end
    end

    class SuccessResponse < Response
      base_body({ status: 'OK' }.freeze)
    end

    class ErrorResponse < Response
      base_body({ status: 'ERROR' }.freeze)
    end

    module Responses
      class OK < SuccessResponse
        status :ok
      end

      class NotFound < ErrorResponse
        status :not_found
      end

      class UnprocessableEntity < ErrorResponse
        status :unprocessable_entity
      end
    end
  end
end

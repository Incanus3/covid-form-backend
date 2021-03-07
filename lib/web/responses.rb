require 'dry/core/class_attributes'

module Utils
  module Web
    class Response
      extend Dry::Core::ClassAttributes

      defines :status, type: ::Symbol

      status :override_me

      attr_value_initialize :body, :headers, [json: true]
      attr_query :json?

      def self.base_body
        {}
      end

      def self.with(fields)
        new(base_body.merge(fields.to_h), {})
      end

      def self.with_no_body
        new('', {}, json: false)
      end

      def status
        self.class.status
      end

      # this may not be needed if we define destructuring
      def deconstruct
        [status, body, headers]
      end
    end

    class SuccessResponse < Response
      def self.base_body
        { status: 'OK' }
      end
    end

    class ErrorResponse < Response
      def self.base_body
        { status: 'ERROR', code: code }
      end

      def self.code
        status
      end
    end

    module Responses
      class OK < SuccessResponse
        status :ok
      end

      class NoContent < SuccessResponse
        status :no_content
      end

      class NotFound < ErrorResponse
        status :not_found
      end

      class Forbidden < ErrorResponse
        status :forbidden
      end

      class MethodNotAllowed < ErrorResponse
        status :method_not_allowed
      end

      class UnprocessableEntity < ErrorResponse
        status :unprocessable_entity

        def self.code
          :validation_failed
        end
      end

      class InternalServerError < ErrorResponse
        status :internal_server_error
      end
    end
  end
end

require 'app/services/registration'

module CovidForm
  module Web
    module Serialization
      class Serializer
        BASE_SUCCESS_RESPONSE = { status: 'OK'    }.freeze
        BASE_ERROR_RESPONSE   = { status: 'ERROR' }.freeze

        def self.success_response_with(fields)
          BASE_SUCCESS_RESPONSE.merge(fields.to_h)
        end

        def self.error_response_with(fields)
          BASE_ERROR_RESPONSE.merge(fields.to_h)
        end
      end

      class ValidationErrorsSerializer < Serializer
        def self.serialize(errors)
          [:unprocessable_entity, error_response_with(errors)]
        end
      end

      class RegistrationResultSerializer < Serializer
        def self.serialize(result)
          case result
          in Services::Registration::Success({ client: client, registration: registration })
            [:ok, success_response_with(client: client.to_h, registration: registration.to_h)]
          in Services::Registration::Failure(message)
            [:unprocessable_entity, error_response_with(error: [message])]
          end
        end
      end
    end
  end
end

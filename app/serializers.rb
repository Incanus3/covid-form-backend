require 'app/registration'

module CovidForm
  class Serializer
    BASE_SUCCESS_RESPONSE = { status: 'OK'    }.freeze
    BASE_ERROR_RESPONSE   = { status: 'ERROR' }.freeze

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
      in Registration::Success()
        [:ok, BASE_SUCCESS_RESPONSE]
      in Registration::ClientAlreadyExists(message)
        [:conflict, error_response_with(error: message)]
      in Registration::Failure(message)
        [:unprocessable_entity, error_response_with(error: message)]
      end
    end
  end
end

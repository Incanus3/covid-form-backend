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
          in Services::Registration::ClientAlreadyRegisteredForDate({ client: client, date: date })
            message = I18n.t('registration.client_already_registered_for_date',
                             insurance_number: client.insurance_number, date: I18n.l(date))

            [:unprocessable_entity, error_response_with(error: [message])]
          else
            # :nocov:
            raise "invalid registration result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end

      class ExportResultSerializer < Serializer
        def self.serialize(result)
          case result
          in Services::Export::Success(output)
            [:ok, success_response_with({ csv: output })]
          in Services::Export::Failure(output)
            [:unprocessable_entity, error_response_with(error: [output])]
          else
            # :nocov:
            raise "invalid export result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end
    end
  end
end

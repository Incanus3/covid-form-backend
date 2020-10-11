require 'lib/utils'
require 'app/services/registration'
require 'app/web/services/authentication'

module CovidForm
  module Web
    module Serialization
      class Serializer
        BASE_SUCCESS_BODY = { status: 'OK'    }.freeze
        BASE_ERROR_BODY   = { status: 'ERROR' }.freeze
        ERROR_STATUS      = :unprocessable_entity

        def self.success_response_with(fields)
          [:ok, self::BASE_SUCCESS_BODY.merge(fields.to_h)]
        end

        def self.error_response_with(fields)
          [self::ERROR_STATUS, self::BASE_ERROR_BODY.merge(fields.to_h)]
        end
      end

      class ValidationErrorsSerializer < Serializer
        def self.serialize(errors)
          errors_hash = Utils::Hash.map_keys(errors.to_h, ->(key) { key.nil? ? 'error' : key })

          error_response_with(errors_hash)
        end
      end

      class AuthenticationFailureSerializer < Serializer
        ERROR_STATUS = :unauthorized

        def self.error_response_with(...)
          super(error: "#{I18n.t('authentication.authentication_failed')}: #{I18n.t(...)}")
        end

        def self.serialize(result)
          case result
          in Authentication::MissingAuthorizationHeader(_)
            error_response_with('authentication.missing_auth_header')
          in Authentication::MalformedAuthorizationHeader(_)
            error_response_with('authentication.malformed_auth_header')
          in Authentication::UnrecognizedAuthenticationMethod(method)
            error_response_with('authentication.unrecognized_auth_method', method: method)
          in Authentication::BadCredentials(_)
            error_response_with('authentication.bad_credentials')
          else
            # :nocov:
            raise "invalid authentication result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end

      class RegistrationResultSerializer < Serializer
        def self.serialize(result)
          case result
          in Services::Registration::Success({ client: client, registration: registration })
            success_response_with(client: client.to_h, registration: registration.to_h)
          in Services::Registration::ClientAlreadyRegisteredForDate({ client: client, date: date })
            message = I18n.t('registration.client_already_registered_for_date',
                             insurance_number: client.insurance_number, date: I18n.l(date))

            error_response_with(error: [message])
          in Services::Registration::DailyRegistrationLimitReached({ date: date })
            message = I18n.t('registration.daily_registration_limit_reached', date: I18n.l(date))

            error_response_with(error: [message])
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
            success_response_with({ csv: output })
          in Services::Export::Failure(output)
            error_response_with(error: [output])
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

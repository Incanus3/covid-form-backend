require 'lib/utils'
require 'app/services/registration'
require 'app/web/services/authentication'

module CovidForm
  module Web
    module Serializers
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

      class ValidationErrors < Serializer
        def self.serialize(errors)
          errors_hash = Utils::Hash.map_keys(errors.to_h, ->(key) { key.nil? ? 'error' : key })

          error_response_with(errors_hash)
        end
      end

      class AuthenticationFailure < Serializer
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

      class RegistrationResult < Serializer
        def self.serialize(result) # rubocop:disable Metrics/MethodLength
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
          in Services::Registration::SlotRegistrationLimitReached({ date: date, slot: slot })
            message = I18n.t(
              'registration.slot_registration_limit_reached',
              date: I18n.l(date), slot: TimeSlot.formatted_time_range(slot),
            )

            error_response_with(error: [message])
          in Services::Registration::NonexistentTimeSlot({ id: time_slot_id })
            message = I18n.t('registration.nonexistent_time_slot', id: time_slot_id)

            error_response_with(error: [message])
          else
            # :nocov:
            raise "invalid registration result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end

      class ExportResult < Serializer
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

      class FullDatesResult < Serializer
        def self.serialize(result)
          case result
          in Services::Capacity::Success(dates: dates)
            success_response_with(dates: dates)
          # in Services::Capacity::Failure(message)
          #   error_response_with(error: [message])
          else
            # :nocov:
            raise "invalid export result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end

      class TimeSlot < Serializer
        class << self
          def serialize_many(time_slots)
            success_response_with(time_slots: time_slots.map { do_serialize(_1) })
          end

          def formatted_time_range(time_slot)
            "#{Utils::Time.format(time_slot.start_time)}-#{Utils::Time.format(time_slot.end_time)}"
          end

          private

          def do_serialize(time_slot)
            output = {
              id:         time_slot.id,
              name:       time_slot.name,
              start_time: Utils::Time.format(time_slot.start_time),
              end_time:   Utils::Time.format(time_slot.end_time),
            }

            # :nocov:
            output[:time_range] = time_slot.time_range if time_slot.respond_to?(:time_range)
            # :nocov:

            output
          end
        end
      end
    end
  end
end

require 'lib/utils'
require 'lib/web/responses'
require 'app/services/registration'

module CovidForm
  module Web
    Responses = Utils::Web::Responses

    module Serializers
      class Serializer # rubocop:disable Style/StaticClass
        def self.serialize(something)
          raise NotImplementedError
        end

        def self.serialize_many(somethings)
          raise NotImplementedError
        end
      end

      class Error < Serializer
        def self.serialize(error)
          Responses::InternalServerError.with(message: "#{error.class.name}: #{error.message}")
        end
      end

      class ValidationErrors < Serializer
        def self.serialize(errors)
          errors_hash = Utils::Hash.map_keys(errors.to_h, ->(key) { key.nil? ? 'error' : key })

          Responses::UnprocessableEntity.with(errors_hash)
        end
      end

      class RegistrationResult < Serializer
        def self.serialize(result) # rubocop:disable Metrics/MethodLength
          case result
          in Services::Registration::Success({ client: client, registration: registration })
            Responses::OK.with(client: client.to_h, registration: registration.to_h)
          in Services::Registration::ClientAlreadyRegisteredForDate({ client: client, date: date })
            message = I18n.t('registration.client_already_registered_for_date',
                             insurance_number: client.insurance_number, date: I18n.l(date))

            Responses::UnprocessableEntity.with(error: [message])
          in Services::Registration::DailyRegistrationLimitReached({ date: date })
            message = I18n.t('registration.daily_registration_limit_reached', date: I18n.l(date))

            Responses::UnprocessableEntity.with(error: [message])
          in Services::Registration::SlotRegistrationLimitReached({ date: date, slot: slot })
            message = I18n.t(
              'registration.slot_registration_limit_reached',
              date: I18n.l(date), slot: TimeSlot.formatted_time_range(slot),
            )

            Responses::UnprocessableEntity.with(error: [message])
          in Services::Registration::NonexistentTimeSlot({ id: time_slot_id })
            message = I18n.t('registration.nonexistent_time_slot', id: time_slot_id)

            Responses::UnprocessableEntity.with(error: [message])
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
          in Services::Export::Success({ csv: csv, encoding: encoding })
            Responses::OK.new(
              csv, { 'Content-Type' => "text/csv;charset=#{encoding.downcase}" }, json: false
            )
          in Services::Export::Failure(output)
            Responses::UnprocessableEntity.with(error: [output])
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
            Responses::OK.with(dates: dates)
          # in Services::Capacity::Failure(message)
          #   Responses::UnprocessableEntity.with(error: [message])
          else
            # :nocov:
            raise "invalid export result to serialize: #{result.inspect}"
            # :nocov:
          end
        end
      end

      class CRUDServiceResult < Serializer
        def self.serialize(service, result)
          model_name = Utils::Class.name(service.model)

          case result
          in CRUD::CRUDService::Success(entity: entity)
            Serializers.const_get(model_name).serialize(entity)
          in CRUD::CRUDService::Success(entities: entities)
            Serializers.const_get(model_name).serialize_many(entities)
          in CRUD::CRUDService::NotFound({ model: model, id: id })
            Responses::NotFound.with(error: "#{model_name} with id #{id} not found")
          end
        end
      end

      class ExamType < Serializer
        class << self
          def serialize_many(exam_types)
            Responses::OK.with(exam_types: exam_types.map { do_serialize(_1) })
          end

          private

          def do_serialize(exam_type)
            { id: exam_type.id, description: exam_type.description }
          end
        end
      end

      class TimeSlot < Serializer
        class << self
          def serialize_many(time_slots, with_coefficient: true)
            Responses::OK.with(
              time_slots: time_slots.map { do_serialize(_1, with_coefficient: with_coefficient) },
            )
          end

          def serialize(...)
            Responses::OK.with(time_slot: do_serialize(...))
          end

          def formatted_time_range(time_slot)
            "#{Utils::Time.format(time_slot.start_time)}-#{Utils::Time.format(time_slot.end_time)}"
          end

          private

          def do_serialize(time_slot, with_coefficient: true)
            output = {
              id:         time_slot.id,
              name:       time_slot.name,
              start_time: Utils::Time.format(time_slot.start_time, remove_leading_zeros: false),
              end_time:   Utils::Time.format(time_slot.end_time,   remove_leading_zeros: false),
            }

            output[:limit_coefficient] = time_slot.limit_coefficient if with_coefficient

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

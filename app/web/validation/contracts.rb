require 'dry-validation'
require_relative 'types'

module CovidForm
  module Web
    module Validation
      class Contract < Dry::Validation::Contract
        # config.messages.default_locale = :cz

        # Dry::Validation.load_extensions(:monads)
        # Dry::Validation.load_extensions(:predicates_as_macros)
        # import_predicates_as_macros
      end

      ClientSchema = Dry::Schema.JSON {
        required(:first_name       ).filled(Types::Strict::String)
        required(:last_name        ).filled(Types::Strict::String)
        required(:municipality     ).filled(Types::Strict::String)
        required(:zip_code         ).filled(Types::ZipCode)
        required(:email            ).filled(Types::Email)
        required(:phone_number     ).filled(Types::PhoneNumber)
        required(:insurance_number ).filled(Types::Coercible::String)
        required(:insurance_company).filled(Types::Coercible::Integer)
      }

      ExamSchema = Dry::Schema.JSON {
        required(:requestor_type).filled(Types::RequestorType)
        required(:exam_type     ).filled(Types::ExamType)
        required(:exam_date     ).filled(Types::JSON::Date)
        required(:time_slot_id  ).filled(Types::Integer)
      }

      class RegistrationContract < Contract
        def self.cf_config
          CovidForm::Dependencies[:config]
        end

        def self.valid_workday?(date)
          cf_config[:allow_registration_for_weekends] || !(date.saturday? || date.sunday?)
        end

        def self.valid_registration_time_for?(date, time = Time.now)
          cf_config[:allow_registration_for_today_after_10] || date != Date.today || time.hour < 10
        end

        def self.invalid_workday_message
          [
            I18n.t('registration.registration'),
            I18n.t('validation.must_be_a_workday'),
          ].join(' ')
        end

        def self.invalid_registration_time_message
          [
            I18n.t('registration.registration_for_today'),
            I18n.t('validation.only_possible_before',
                   time: I18n.l(Utils::Time.today_at(10, 0), format: :time_only)),
          ].join(' ')
        end

        json(ClientSchema, ExamSchema)

        rule(:exam_date) do
          key.failure(I18n.t('validation.must_not_be_in_past')) if value < Date.today

          unless RegistrationContract.valid_workday?(value)
            base.failure(RegistrationContract.invalid_workday_message)
          end

          unless RegistrationContract.valid_registration_time_for?(value)
            base.failure(RegistrationContract.invalid_registration_time_message)
          end
        end
      end

      ExportSchema = Dry::Schema.JSON {
        required(:start_date).filled(Types::JSON::Date.default(Date.today))
        required(:end_date  ).filled(Types::JSON::Date.default(Date.today + 7))
      }

      class ExportContract < Contract
        json(ExportSchema)
      end
    end
  end
end

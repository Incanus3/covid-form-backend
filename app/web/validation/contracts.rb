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
      }

      class RegistrationContract < Contract
        json(ClientSchema, ExamSchema)

        rule(:exam_date) do
          key.failure(I18n.t('validation.must_not_be_in_past')) if value < Date.today

          if value == Date.today && Time.now.hour >= 10
            base.failure([
              I18n.t('registration.registration_for_today'),
              I18n.t('validation.only_possible_before',
                     time: I18n.l(Utils::Time.today_at(10, 0), format: :time_only)),
            ].join(' '))
          end
        end
      end
    end
  end
end

require 'dry-validation'
require_relative 'schemas'

module CovidForm
  module Web
    module Validation
      module Contracts
        class Contract < Dry::Validation::Contract
          # config.messages.default_locale = :cz

          # Dry::Validation.load_extensions(:monads)
          # Dry::Validation.load_extensions(:predicates_as_macros)
          # import_predicates_as_macros
        end

        class Registration < Contract
          def self.cf_config
            CovidForm::Dependencies[:config]
          end

          def self.valid_workday?(date)
            cf_config[:allow_registration_for_weekends] || !(date.saturday? || date.sunday?)
          end

          def self.valid_registration_time_for?(date, time = Time.now)
            cf_config[:allow_registration_for_today_after_10] \
              || date != Date.today \
              || time.hour < 10
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

          json do
            required(:client).value(Schemas::Client)
            required(:exam  ).value(Schemas::Exam)
          end

          rule(exam: :exam_date) do
            key.failure(I18n.t('validation.must_not_be_in_past')) if value < Date.today

            unless Registration.valid_workday?(value)
              base.failure(Registration.invalid_workday_message)
            end

            unless Registration.valid_registration_time_for?(value)
              base.failure(Registration.invalid_registration_time_message)
            end
          end
        end

        class Export < Contract
          json(Schemas::Export)
        end

        class FullDates < Contract
          json(Schemas::FullDates)
        end
      end
    end
  end
end

require 'dry-validation'
require 'lib/utils'
require_relative 'schemas'
require_relative 'messages'

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
          INSURANCE_NUMBER_REGEX =
            /^(?<year>\d\d)(?<month>\d\d)(?<day>\d\d)(?<suffix>\d{3,4})$/.freeze

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

          json do
            required(:client).value(Schemas::Client)
            required(:exam  ).value(Schemas::Exam)
          end

          rule(exam: :exam_date) do
            key.failure( Messages.must_not_be_in_past) if     value < Date.today
            base.failure(Messages.not_a_valid_workday) unless Registration.valid_workday?(value)

            unless Registration.valid_registration_time_for?(value)
              base.failure(Messages.not_a_valid_registration_time)
            end
          end

          # rubocop:disable Metrics/BlockLength, Metrics/BlockNesting
          rule(client: :insurance_number) do
            unless values[:client][:insurance_company] == 999
              key.failure(Messages.must_not_be_shorter(than: 9 )) if value.length < 9
              key.failure(Messages.must_not_be_longer( than: 10)) if value.length > 10
              key.failure(Messages.must_only_contain_numbers) unless value.match?(/^\d+$/)

              if (match = value.match(INSURANCE_NUMBER_REGEX))
                year, month, day, suffix =
                  [*match.values_at(:year, :month, :day).map(&:to_i), match[:suffix]]

                month -= 50 if month > 50

                if month > 20
                  rc_plus = true
                  month  -= 20
                end

                if day > 40
                  ecp  = true
                  day -= 40
                end

                if month < 1 || month > 12
                  key.failure(Messages.not_a_valid_month(month))
                elsif day < 1 || day > Utils::Date.days_in_month(month: month, year: year)
                  key.failure(Messages.not_a_valid_day_of_month(day, month))
                end

                if value.length == 9
                  key.failure(Messages.must_not_end_with('000'))            if suffix == '000'
                  key.failure(Messages.birth_year_must_not_be_before(1900)) if year > 53
                else
                  unless Utils::Number.divisible_by?(value.to_i, 11)
                    key.failure(Messages.must_be_divisible_by(11))
                  end
                end

                key.failure(Messages.must_not_end_with(suffix)) if ecp && suffix[0, 3].to_i < 600
                key.failure(Messages.must_not_be_both('RČ+', 'EČP')) if rc_plus && ecp
              end
            end
          end
          # rubocop:enable Metrics/BlockLength, Metrics/BlockNesting
        end

        class Export < Contract
          json(Schemas::Export)

          rule(:start_date, :end_date) do
            if values[:start_date] > values[:end_date]
              base.failure('end_date must be after start_date')
            end
          end
        end

        class FullDates < Contract
          json(Schemas::FullDates)

          rule(:start_date, :end_date) do
            if values[:start_date] > values[:end_date]
              base.failure('end_date must be after start_date')
            end
          end
        end
      end
    end
  end
end

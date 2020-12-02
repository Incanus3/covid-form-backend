module CovidForm
  module Web
    module Validation
      module Messages
        module_function

        def must_be_divisible_by(divisor)
          I18n.t('validation.must_be_divisible_by', divisor: divisor)
        end

        def must_only_contain_numbers
          I18n.t('validation.must_only_contain', what: I18n.t('entities.number.plural'))
        end

        def must_not_be_shorter(than:)
          I18n.t('validation.must_not_be_shorter', than: than )
        end

        def must_not_be_longer(than:)
          I18n.t('validation.must_not_be_longer', than: than )
        end

        def must_not_be_both(variant1, variant2)
          I18n.t('validation.must_not_be_both', variant1: variant1, variant2: variant2)
        end

        def must_not_end_with(suffix)
          I18n.t('validation.must_not_end_with', suffix: suffix)
        end

        def must_not_be_in_past
          I18n.t('validation.must_not_be_in_past')
        end

        def not_a_valid_month(month)
          I18n.t('validation.not_a_valid',
                 value: month, what: I18n.t('entities.date.parts.month'))
        end

        def not_a_valid_day_of_month(day, month)
          I18n.t('validation.not_a_valid',
                 value: day,
                 what:  [
                   I18n.t('entities.date.parts.day_of_month'),
                   I18n.t('date.month_names')[month],
                 ].join(' '))
        end

        def not_a_valid_workday
          [
            I18n.t('registration.registration'),
            I18n.t('validation.must_be_a_workday'),
          ].join(' ')
        end

        def birth_year_must_not_be_before(year)
          [
            I18n.t('entities.client.birth_year'),
            I18n.t('validation.must_not_be_before', time: year),
          ].join(' ')
        end

        def not_a_valid_registration_time(deadline)
          [
            I18n.t('registration.registration_for_today'),
            I18n.t('validation.only_possible_before', time: I18n.l(deadline, format: :time_only)),
          ].join(' ')
        end
      end
    end
  end
end

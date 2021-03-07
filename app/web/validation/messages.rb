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
          I18n.t('validation.must_not_be_shorter', than: than)
        end

        def must_not_be_longer(than:)
          I18n.t('validation.must_not_be_longer', than: than)
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

        def not_a_valid_exam_type(exam_type, allowed_values:)
          [
            I18n.t(
              'validation.not_a_valid',
              value: quote(exam_type), what: I18n.t('entities.exam.exam_type'),
            ),
            I18n.t(
              'validation.must_be_one_of',
              allowed_values: allowed_values.map { quote(_1) }.join(', '),
            ),
          ].join(', ')
        end

        def not_a_valid_exam_date(exam_date, allowed_dates)
          [
            I18n.t(
              'validation.not_a_valid',
              value: I18n.l(exam_date), what: I18n.t('entities.exam.exam_date'),
            ),
            I18n.t(
              'validation.must_be_between',
              start: I18n.l(allowed_dates.start_date),
              end:   I18n.l(allowed_dates.end_date),
            ),
          ].join(', ')
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

        def quote(string)
          "'#{string}'"
        end
      end
    end
  end
end

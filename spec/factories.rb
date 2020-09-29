require 'faker'
require 'app/types'
require 'app/entities'

module Faker
  class IDNumber
    class << self
      def valid_czech_id_number
        [
          Faker::Date.birthday.strftime('%y%m%d'),
          Faker::Number.number(digits: 4),
        ].join
      end

      alias czech_id_number valid_czech_id_number
    end
  end
end

FactoryBot.define do
  factory :client do
    first_name   { Faker::Name.first_name  }
    last_name    { Faker::Name.last_name   }
    municipality { Faker::Address.city     }
    zip_code     { Faker::Address.zip_code }

    email { Faker::Internet.email(name: "#{first_name}#{last_name}") }

    phone_number do
      [
        Faker::PhoneNumber.phone_number,
        Faker::PhoneNumber.phone_number_with_country_code,
      ].sample
    end

    insurance_number  { Faker::IDNumber.czech_id_number }
    insurance_company { Faker::Number.number(digits: 3) }
  end

  factory :exam do
    requestor_type { CovidForm::Types::RequestorType.values.sample }
    exam_type      { CovidForm::Types::ExamType.values.sample      }
    exam_date      { Faker::Date.forward(days: 60)                 }
  end
end

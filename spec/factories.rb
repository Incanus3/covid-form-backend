require 'app/entities'
require 'app/web/validation/types'

FactoryBot.define do
  factory :client, class: CovidForm::Entities::Client do
    first_name        { Faker::Name.first_name  }
    last_name         { Faker::Name.last_name   }

    municipality      { Faker::Address.city     }
    zip_code          { Faker::Address.zip_code }

    email             { Faker::Internet.email(name: "#{first_name} #{last_name}") }
    phone_number      { Faker::CEPhoneNumber.phone_number                         }

    insurance_number  { Faker::CZIDNumber.valid         }
    insurance_company { Faker::Number.number(digits: 3) }

    trait :invalid_email do
      email { 'xxx' }
    end

    factory :client_with_invalid_email, traits: [:invalid_email]
  end

  factory :exam, class: CovidForm::Entities::Registration do
    requestor_type { CovidForm::Types::RequestorType.values.sample }
    exam_type      { CovidForm::Types::ExamType.values.sample      }
    exam_date      { Faker::Date.forward(days: 60)                 }

    trait :past_date do
      exam_date { Faker::Date.backward }
    end

    factory :exam_with_past_date, traits: [:past_date]
  end
end

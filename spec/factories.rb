require 'app/types'
require 'app/entities'

FactoryBot.define do
  factory :client do
    first_name        { Faker::Name.first_name  }
    last_name         { Faker::Name.last_name   }

    municipality      { Faker::Address.city     }
    zip_code          { Faker::Address.zip_code }

    email             { Faker::Internet.email(name: "#{first_name} #{last_name}") }
    phone_number      { Faker::CEPhoneNumber.phone_number                         }

    insurance_number  { Faker::CZIDNumber.valid         }
    insurance_company { Faker::Number.number(digits: 3) }
  end

  factory :exam do
    requestor_type { CovidForm::Types::RequestorType.values.sample }
    exam_type      { CovidForm::Types::ExamType.values.sample      }
    exam_date      { Faker::Date.forward(days: 60)                 }
  end
end

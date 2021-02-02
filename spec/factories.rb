require 'app/entities'
require 'app/dependencies'
require 'app/web/validation/types'

FactoryBot.define do
  factory :client, class: CovidForm::Entities::Client do
    first_name        { Faker::Name.first_name  }
    last_name         { Faker::Name.last_name   }

    municipality      { Faker::Address.city     }
    zip_code          { Faker::Address.zip_code }

    email             { Faker::Internet.email(name: "#{first_name} #{last_name}") }
    phone_number      { Faker::CEPhoneNumber.phone_number                         }

    insurance_company           { Faker::Number.number(digits: 3)             }
    sequence(:insurance_number) { |n| "500101#{(n % 600).to_s.rjust(3, '0')}" }

    trait :invalid_email do
      email { 'xxx' }
    end

    trait :random_insurance_number do
      insurance_number {
        "#{Faker::Date.birthday.strftime('%y%m%d')}#{Faker::Number.number(digits: 4)}"
      }
    end

    factory :client_with_invalid_email,           traits: [:invalid_email]
    factory :client_with_random_insurance_number, traits: [:random_insurance_number]
  end

  factory :exam, class: CovidForm::Entities::Registration do
    transient do
      db               { CovidForm::Dependencies[:db] }
      max_days_forward { 7                            }
    end

    requestor_type { CovidForm::Web::Validation::Types::RequestorType.values.sample }
    exam_type      { db.exam_types.all_ids.sample                                   }
    exam_date      { Faker::Date.forward(days: max_days_forward)                    }
    time_slot_id   { db.time_slots.ids.sample                                       }

    trait :past_date do
      exam_date { Faker::Date.backward }
    end

    factory :exam_with_past_date, traits: [:past_date]
  end
end

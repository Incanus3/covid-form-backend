require 'dry-schema'
require 'app/types'

module CovidForm
  module Web
    REGISTRATION_SCHEMA = Dry::Schema.JSON {
      required(:requestor_type   ).filled(Types::RequestorType)
      required(:exam_type        ).filled(Types::ExamType)
      required(:exam_date        ).filled(Types::JSON::Date).value(gteq?: Date.today)
      required(:first_name       ).filled(Types::Strict::String)
      required(:last_name        ).filled(Types::Strict::String)
      required(:municipality     ).filled(Types::Strict::String)
      required(:zip_code         ).filled(Types::ZipCode)
      required(:email            ).filled(Types::Email)
      required(:phone_number     ).filled(Types::PhoneNumber)
      required(:insurance_number ).filled(Types::Coercible::String)
      required(:insurance_company).filled(Types::Coercible::Integer)
    }.freeze
  end
end

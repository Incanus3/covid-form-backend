require 'dry-schema'
require_relative 'types'

module CovidForm
  module Web
    module Validation
      module Schemas
        Client = Dry::Schema.JSON {
          required(:first_name       ).filled(Types::Strict::String)
          required(:last_name        ).filled(Types::Strict::String)
          required(:municipality     ).filled(Types::Strict::String)
          required(:zip_code         ).filled(Types::ZipCode)
          required(:email            ).filled(Types::Email)
          required(:phone_number     ).filled(Types::PhoneNumber)
          required(:insurance_number ).filled(Types::Coercible::String)
          required(:insurance_company).filled(Types::Coercible::Integer)
        }

        Exam = Dry::Schema.JSON {
          required(:requestor_type).filled(Types::RequestorType)
          required(:exam_type     ).filled(Types::ExamType)
          required(:exam_date     ).filled(Types::JSON::Date)
          required(:time_slot_id  ).filled(Types::Integer)
        }

        Export = Dry::Schema.JSON {
          required(:start_date).filled(Types::JSON::Date.default { Date.today     })
          required(:end_date  ).filled(Types::JSON::Date.default { Date.today + 7 })
        }

        FullDates = Dry::Schema.JSON {
          required(:start_date).filled(Types::JSON::Date.default { Date.today     })
          required(:end_date  ).filled(Types::JSON::Date.default { Date.today + 7 })
        }
      end
    end
  end
end

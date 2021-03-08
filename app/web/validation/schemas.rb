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

        AvailableTimeSlots = Dry::Schema.JSON {
          required(:date     ).filled(Types::JSON::Date.default { Date.today })
          required(:exam_type).filled(Types::Strict::String)
        }

        Export = Dry::Schema.JSON {
          required(:start_date).filled(Types::JSON::Date.default { Date.today     })
          required(:end_date  ).filled(Types::JSON::Date.default { Date.today + 7 })
        }

        FullDates = Dry::Schema.JSON {
          required(:start_date).filled(Types::JSON::Date.default { Date.today     })
          required(:end_date  ).filled(Types::JSON::Date.default { Date.today + 7 })
        }

        TimeSlot = Dry::Schema.JSON {
          required(:name             ).filled(Types::Strict::String)
          required(:start_time       ).filled(Types::JSON::Time)
          required(:end_time         ).filled(Types::JSON::Time)
          required(:limit_coefficient).filled(Types::Integer)

          optional(:exam_types).array(Types::Strict::String)
        }

        ExamType = Dry::Schema.JSON {
          required(:description).filled(Types::Strict::String)
        }

        DailyOverride = Dry::Schema.JSON {
          required(:date              ).filled(Types::JSON::Date)
          required(:registration_limit).filled(Types::Integer)
        }

        Setting = Dry::Schema.JSON {
          required(:key  ).filled(Types::Strict::String).value(excludes?: 'auth')
          required(:value).filled(Types::Nominal::Any)
        }
      end
    end
  end
end

$LOAD_PATH.unshift '.'

require 'roda'
require 'dry-schema'

require 'app/types'
require 'app/registration'

module CovidForm
  class App < Roda
    plugin :halt
    plugin :all_verbs
    plugin :not_allowed
    plugin :symbol_status
    plugin :json
    plugin :json_parser

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

    route do |r|
      r.root do # GET /
        '<p>tady bude seznam rout</p>'
      end

      r.is 'register' do
        r.post do # POST /register
          validation_result = REGISTRATION_SCHEMA.call(request.params)

          if validation_result.success?
            result = Registration.perform(validation_result.to_h)

            { result: result }
          else
            response.status = :bad_request

            validation_result.errors.to_h
          end
        end
      end
    end
  end
end

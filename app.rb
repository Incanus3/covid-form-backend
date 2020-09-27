$LOAD_PATH.unshift './app'
$LOAD_PATH.unshift './lib'

require 'roda'
require 'dry-schema'
require 'dry-types'
require 'registration'

ZIP_REGEX    = /^\d{3} ?\d{2}$/.freeze
EMAIL_REGEX  = /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-.]+\.[a-zA-Z0-9\-]{2,}$/.freeze
PHONE_PREFIX = '(\+|00)\d{2,3}'.freeze
PHONE_REGEX  = /^(#{PHONE_PREFIX}|\(#{PHONE_PREFIX}\))? ?[1-9]\d{2} ?\d{3} ?\d{3}$/.freeze

module CovidForm
  module Types
    include Dry.Types()
  end

  class App < Roda
    plugin :halt
    plugin :all_verbs
    plugin :not_allowed
    plugin :symbol_status
    plugin :json
    plugin :json_parser

    REGISTRATION_SCHEMA = Dry::Schema.JSON { # rubocop:disable Metrics/BlockLength
      required(:requestor_type)
        .filled(Types::Strict::String)
        .value(included_in?: %w[pl khs samopl])
      required(:exam_type)
        .filled(Types::Strict::String)
        .value(included_in?: %w[pcr rapid])
      required(:exam_date)
        .filled(Types::JSON::Date)
        .value(gteq?: Date.today)
      required(:first_name)
        .filled(Types::Strict::String)
      required(:last_name)
        .filled(Types::Strict::String)
      required(:municipality)
        .filled(Types::Strict::String)
      required(:zip_code)
        .filled(Types::Coercible::String)
        .value(format?: ZIP_REGEX)
      required(:email)
        .filled(Types::Strict::String)
        .value(format?: EMAIL_REGEX)
      required(:phone_number)
        .filled(Types::Coercible::String)
        .value(format?: PHONE_REGEX)
      required(:insurance_number )
        .filled(Types::Coercible::String)
      required(:insurance_company)
        .filled(Types::Coercible::Integer)
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

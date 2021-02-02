require 'dry-types'

ZIP_REGEX    = /^\d{3} ?\d{2}$/.freeze
EMAIL_REGEX  = /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-.]+\.[a-zA-Z0-9\-]{2,}$/.freeze
PHONE_PREFIX = '(\+|00)\d{2,3}'.freeze
PHONE_REGEX  = /^(#{PHONE_PREFIX}|\(#{PHONE_PREFIX}\))? ?[1-9]\d{2} ?\d{3} ?\d{3}$/.freeze

module CovidForm
  module Web
    module Validation
      module Types
        include Dry.Types()

        ExamType      = Strict::String.constructor(&:downcase)
        RequestorType = Strict::String.constructor(&:downcase).enum('pl', 'khs', 'samopl', 'ag')

        Email         = Strict::String.constrained(format: EMAIL_REGEX)
        PhoneNumber   = Coercible::String.constrained(format: PHONE_REGEX)
          .constructor { _1.gsub(/[\s()]/, '') }
        ZipCode       = Coercible::String.constrained(format: ZIP_REGEX)
          .constructor { _1.gsub(/\s/, '') }
      end
    end
  end
end

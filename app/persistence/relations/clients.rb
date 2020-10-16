require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class Clients < Utils::Persistence::Relation
        schema(:clients) do
          attribute :id,                Types::Integer
          attribute :first_name,        Types::String
          attribute :last_name,         Types::String
          attribute :municipality,      Types::String
          attribute :zip_code,          Types::String
          attribute :email,             Types::String
          attribute :phone_number,      Types::String
          attribute :insurance_number,  Types::String
          attribute :insurance_company, Types::Integer

          primary_key :id

          associations do
            has_many :registrations
          end
        end

        def by_insurance_number(number)
          where(insurance_number: number)
        end
      end
    end
  end
end

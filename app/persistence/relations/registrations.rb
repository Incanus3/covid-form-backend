require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class Registrations < Utils::Persistence::Relation
        schema(:registrations) do
          attribute :id,             Types::Integer
          attribute :client_id,      Types::ForeignKey(:clients)
          attribute :registered_at,  Types::DateTime
          # TODO: map these to enum types
          attribute :requestor_type, Types::String
          attribute :exam_type,      Types::String
          attribute :exam_date,      Types::Date

          primary_key :id

          associations do
            belongs_to :client
          end
        end

        def for_client(client)
          where(client_id: client.id)
        end

        def by_date(date)
          where(exam_date: date)
        end
      end
    end
  end
end

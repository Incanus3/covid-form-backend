require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class Registrations < Utils::Persistence::Relation
        schema(:registrations) do
          attribute :id,             Types::Integer
          attribute :client_id,      Types::ForeignKey(:clients)
          attribute :time_slot_id,   Types::ForeignKey(:time_slots)
          attribute :registered_at,  Types::DateTime
          # TODO: map these to enum types
          attribute :requestor_type, Types::String
          attribute :exam_type,      Types::String
          attribute :exam_date,      Types::Date

          primary_key :id

          associations do
            belongs_to :client
            belongs_to :time_slot
          end
        end

        def by_date(date)
          where(exam_date: date)
        end

        def for_client(client)
          where(client_id: client.id)
        end

        def for_export
          ts_with_tr = time_slots.with_time_range

          join(clients).join(ts_with_tr)
            .select(registrations[:registered_at], registrations[:requestor_type],
                    registrations[:exam_type],     registrations[:exam_date],
                    column_from(:time_range, ts_with_tr),
                    clients[:last_name],           clients[:first_name],
                    clients[:insurance_number],    clients[:insurance_company],
                    clients[:zip_code],            clients[:municipality],
                    clients[:phone_number],        clients[:email])
        end

        private

        def column_from(column, relation)
          relation.schema.project(column).first
        end
      end
    end
  end
end

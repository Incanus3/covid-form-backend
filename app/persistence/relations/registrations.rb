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

        def by_date_and_slot(date, slot)
          where(exam_date: date, time_slot_id: slot.id)
        end

        def for_client(client)
          where(client_id: client.id)
        end

        def for_export(start_date, end_date)
          slots_with_ranges = time_slots.with_time_range

          join(clients).join(slots_with_ranges)
            .where { (exam_date >= start_date) & (exam_date <= end_date) }
            .select(
              *translated_columns_from(
                registrations,
                %i[registered_at requestor_type exam_type exam_date],
              ),
              translated_column_from(slots_with_ranges, :time_range),
              *translated_columns_from(
                clients,
                %i[last_name first_name insurance_number insurance_company] +
                %i[zip_code municipality phone_number email],
              ),
            )
        end
      end
    end
  end
end

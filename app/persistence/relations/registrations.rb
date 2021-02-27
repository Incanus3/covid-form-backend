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

        def for_date(date)
          where(exam_date: date)
        end

        def for_date_and_slot(date, slot)
          where(exam_date: date, time_slot_id: slot.id)
        end

        def counts_by_date
          select { [exam_date, integer.count(id).as(:registration_count)] }
            .group(:exam_date)
        end

        def counts_by_date_and_slot
          select { [exam_date, time_slot_id, integer.count(id).as(:registration_count)] }
            .group(:exam_date, :time_slot_id)
        end

        def for_client(client)
          where(client_id: client.id)
        end

        def for_export(start_date, end_date)
          slots_with_ranges = time_slots.with_time_range

          join(clients).join(slots_with_ranges)
            .where { (exam_date >= start_date) & (exam_date <= end_date) }
            .select(*columns_for_export(slots_with_ranges))
            .order(
              translated_column_name_from(registrations, :exam_date),
              *translated_column_names_from(clients, [:last_name, :first_name]),
            )
        end

        private

        def columns_for_export(slots_with_ranges)
          [
            translated_column_from(registrations, :exam_type),
            *translated_columns_from(
              clients,
              %i[last_name first_name insurance_number insurance_company] +
              %i[zip_code municipality phone_number],
            ),
            translated_column_from(registrations,     :requestor_type),
            translated_column_from(registrations,     :exam_date),
            translated_column_from(slots_with_ranges, :time_range),
            translated_column_from(registrations,     :registered_at),
            translated_column_from(clients,           :email),
          ]
        end
      end
    end
  end
end

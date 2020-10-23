require 'lib/persistence/relation'

module CovidForm
  module Persistence
    module Relations
      class Registrations < Utils::Persistence::Relation
        DATES_WITH_FULL_CAPACITY_RAW_QUERY = <<~RAW.freeze
          with
            date_seq   as (select '%{start_date}'::date + seq.num as date from generate_series(0, %{number_of_days}) as seq(num)),
            reg_counts as (select exam_date, count(id) as reg_count from registrations group by exam_date)
          select date_seq.date from date_seq
          left outer join reg_counts      on date_seq.date = reg_counts.exam_date
          left outer join daily_overrides on date_seq.date = daily_overrides.date
          where coalesce(reg_counts.reg_count, 0) >= coalesce(daily_overrides.registration_limit, %{global_registration_limit})
          order by date_seq.date;
        RAW

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
            .select(*columns_for_export(slots_with_ranges))
            .order(
              translated_column_name_from(registrations, :exam_date),
              *translated_column_names_from(clients, [:last_name, :first_name]),
            )
        end

        def dates_with_full_capacity(start_date, end_date, global_registration_limit:)
          sql = format(DATES_WITH_FULL_CAPACITY_RAW_QUERY, {
            start_date:                start_date,
            number_of_days:            Integer(end_date - start_date),
            global_registration_limit: global_registration_limit,
          })

          read(sql)
        end

        private

        def columns_for_export(slots_with_ranges)
          [
            translated_column_from(registrations, :registered_at),
            translated_column_from(clients,       :email),
            *translated_columns_from(registrations, [:requestor_type, :exam_type]),
            *translated_columns_from(
              clients,
              %i[last_name first_name insurance_number insurance_company] +
              %i[zip_code municipality phone_number],
            ),
            translated_column_from(slots_with_ranges, :time_range),
            translated_column_from(registrations,     :exam_date),
          ]
        end
      end
    end
  end
end

require 'lib/persistence/repository'
require 'app/persistence/queries/registration_limits'

module CovidForm
  module Persistence
    module Repositories
      class Registrations < Utils::Persistence::Repository[:registrations]
        def create(data)
          super({ registered_at: Time.now }.merge(data))
        end

        def create_for_client(data, client)
          create({ client_id: client.id }.merge(data))
        end

        def for_client(client)
          registrations.for_client(client).to_a
        end

        def count_for_date(date)
          registrations.for_date(date).count
        end

        def count_for_date_and_slot(date, slot)
          registrations.for_date_and_slot(date, slot).count
        end

        def dates_with_full_capacity(start_date, end_date, global_registration_limit:)
          registration_capacity_query
            .dates_with_full_capacity(start_date, end_date,
                                      global_registration_limit: global_registration_limit)
        end

        def daily_capacities_for(exam_type_id:, start_date:, end_date:, global_registration_limit:)
          registration_capacity_query.daily_capacities_for(
            global_registration_limit: global_registration_limit,
            exam_type_id:              exam_type_id,
            start_date:                start_date,
            end_date:                  end_date,
          )
        end

        def sql_for_export(start_date, end_date)
          registrations.for_export(start_date, end_date).dataset.sql
        end

        private

        def registration_capacity_query
          Queries::RegistrationCapacity.new(
            db:              default_gateway.connection,
            exam_types:      exam_types,
            time_slots:      time_slots,
            registrations:   registrations,
            daily_overrides: daily_overrides,
          )
        end
      end
    end
  end
end

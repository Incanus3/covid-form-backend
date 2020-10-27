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
          registrations.by_date(date).count
        end

        def count_for_date_and_slot(date, slot)
          registrations.by_date_and_slot(date, slot).count
        end

        def dates_with_full_capacity(start_date, end_date, global_registration_limit:)
          query = Queries::RegistrationCapacity.new(
            db:              default_gateway.connection,
            registrations:   registrations,
            daily_overrides: daily_overrides,
          )

          query.dates_with_full_capacity(start_date, end_date,
                                         global_registration_limit: global_registration_limit)
        end

        def sql_for_export(start_date, end_date)
          registrations.for_export(start_date, end_date).dataset.sql
        end
      end
    end
  end
end

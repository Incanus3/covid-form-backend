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

        # def counts_for_date(date)
        #   counts_by_slot = registrations.for_date(date).counts_by_slot

        #   # # this doesn't work because counts_by_slot loses the all pre-applied operations
        #   # p time_slots.left_join(counts_by_slot)

        #   join_keys = time_slots.associations[:registrations].join_keys
        #   joined = time_slots.new(time_slots.dataset
        #     .left_join(counts_by_slot.dataset, join_keys.invert.map { |k, v| [k.name, v.name] })
        #     .select_append { coalesce(registration_count, 0).as(:registration_count) })
        #   # p joined
        #   # pp joined.with(auto_struct: false).to_a

        #   counts_by_slot.pluck(:time_slot_id, :registration_count).to_h
        # end

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

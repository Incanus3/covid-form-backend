require 'lib/persistence/repository'

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

        def sql_for_export
          registrations
            .join(clients)
            .select(registrations[:registered_at], registrations[:requestor_type],
                    registrations[:exam_type],     registrations[:exam_date],
                    clients[:last_name],           clients[:first_name],
                    clients[:insurance_number],    clients[:insurance_company],
                    clients[:zip_code],            clients[:municipality],
                    clients[:phone_number],        clients[:email])
            .dataset
            .sql
        end
      end
    end
  end
end
require 'dry/monads'
require 'dry/monads/do'

require 'app/dependencies'
require 'app/persistence/repository'

module CovidForm
  module Services
    class Registration
      include Import[:db, :repository]
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:perform)

      class ClientAlreadyRegisteredForDate < Failure
        def initialize(client, date)
          super("client with insurance_number #{client.insurance_number} " \
                "is already registered for #{date}")
        end
      end

      attr_private_initialize [:db, :repository, :data]

      def self.perform(data)
        new(data: data).perform
      end

      def perform
        db.transaction do
          client       = yield create_or_update_client
          registration = yield create_registration(client)

          Success.new({ client: client, registration: registration })
        end
      end

      private

      def create_or_update_client
        client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                      :email, :phone_number, :insurance_number, :insurance_company)

        existing = repository.clients.lock_by_insurance_number(client_data[:insurance_number])

        client =
          if existing.empty?
            repository.clients.create(client_data)
          else
            existing.update_returning(client_data.except(:insurance_number)).first
          end

        Success.new(client)
      end

      def create_registration(client)
        registration_data = self.data
          .slice(:requestor_type, :exam_type, :exam_date)
          .merge({ client_id: client.id })

        begin
          Success.new(repository.registrations.create(registration_data))
        rescue Sequel::UniqueConstraintViolation # FIXME: this is an abstraciton leak
          ClientAlreadyRegisteredForDate.new(client, registration_data[:exam_date])
        end
      end
    end
  end
end

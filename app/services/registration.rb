require 'dry/monads'
require 'dry/monads/do'

require 'app/dependencies'
require 'app/persistence/repository'

module CovidForm
  class Registration
    include Import[:db, :repository]
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:perform)

    attr_private_initialize [:db, :repository, :data]

    def self.perform(data)
      new(data: data).perform
    end

    def perform
      puts '=' * 80
      puts 'in Registration.perform'
      pp self.data

      db.transaction do
        client = yield create_or_update_client

        p client

        Success()
      end
    end

    private def create_or_update_client
      client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                    :email, :phone_number, :insurance_number, :insurance_company)

      existing = repository.clients.lock_by_insurance_number(client_data[:insurance_number])

      client =
        if existing.empty?
          repository.clients.create(client_data)
        else
          existing.update_returning(client_data.except(:insurance_number)).first
        end

      Success(client)
    end
  end
end

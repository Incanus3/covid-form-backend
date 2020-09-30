require 'dry/monads'
require 'dry/monads/do'

require 'app/dependencies'
require 'app/persistence/repository'

module CovidForm
  class Registration
    include Import[:db, :repository]
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:perform)

    class ClientAlreadyExists < Failure
      def initialize(data)
        super("client with insurance_number #{data[:insurance_number]} already exists")
      end
    end

    attr_private_initialize [:db, :repository, :data]

    def self.perform(data)
      new(data: data).perform
    end

    def perform
      puts '=' * 80
      puts 'in Registration.perform'
      pp self.data

      db.transaction do
        _client = yield create_or_update_client

        Success()
      end
    end

    private def create_or_update_client
      client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                    :email, :phone_number, :insurance_number, :insurance_company)

      existing = repository.clients.lock_by_insurance_number(client_data[:insurance_number])

      if existing.empty?
        puts 'creating new client'
        repository.clients.create(client_data)

        Success()
      else
        puts 'client already exists'
        ClientAlreadyExists.new(client_data)
      end
    end
  end
end

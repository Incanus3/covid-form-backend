require 'attr_extras/explicit'
require 'dry/monads'
require 'dry/monads/do'
require 'app/db'

module CovidForm
  class Registration
    extend AttrExtras.mixin
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:perform)

    static_facade :perform, :data

    def perform
      puts '=' * 80
      puts 'in Registration.perform'
      pp self.data

      # TODO: move client data preprocessing logic elsewere

      db.transaction do
        _client = yield create_or_update_client

        Success()
      end
    end

    private def create_or_update_client
      client_data = self.data.slice(:first_name, :last_name, :municipality, :zip_code,
                                    :email, :phone_number, :insurance_number, :insurance_company)
      client_data[:zip_code].gsub!(/\s/, '')

      existing = db[:clients].where(insurance_number: self.data[:insurance_number]).for_update

      if existing.empty?
        puts 'creating new client'
        db[:clients].insert(client_data)

        Success()
      else
        puts 'client already exists'
        Failure("client with insurance_number #{self.data[:insurance_number]} already exists")
      end
    end

    # TODO: use dry-coontainer for this
    private def db
      @db ||= Database[ENV.fetch('APP_ENV', 'development')]
    end
  end
end

require 'dry/monads'
require 'dry/monads/do'

require 'lib/utils'
require 'app/dependencies'
require 'app/mailers/registration_confirmation'

module CovidForm
  module Services
    class Capacity
      include Import[:config, :db]
      include Dry::Monads[:result]

      attr_private_initialize [:config, :db, :start_date, :end_date]

      def full_dates
        dates = db.registrations
          .dates_with_full_capacity(start_date, end_date,
                                    global_registration_limit: config[:daily_registration_limit])

        Success.new(dates: dates)
      end
    end
  end
end

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
        # TODO: start with sth like
        # SELECT start_date + s.date AS dates FROM generate_series(0,14,7) AS s(date);
        # (see https://www.postgresql.org/docs/12/functions-srf.html), than join registration counts
        # and overrides (with default to global limit) to it, add having that will add boolean
        # column for reg_count < limit and select rows for which this is false
        # also take a look at https://www.postgresql.org/docs/12/queries-values.html if needed
        Success.new(dates: [])
      end
    end
  end
end

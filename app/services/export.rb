require 'English'
require 'dry/monads'

module CovidForm
  module Services
    class Export
      include Import[:db, :repository]
      include Dry::Monads[:result]

      static_facade :perform, [:db, :repository]

      def perform
        query        = repository.registrations.for_export
        psql_command = "\\copy (#{query.sql.delete('()')}) to STDOUT CSV HEADER FORCE QUOTE *"
        command      = ("PGPASSWORD=#{db.options[:password]} psql "         \
                        "-h #{db.options[:host]} -p #{db.options[:port]} "  \
                        "-U #{db.options[:user]} #{db.options[:database]} " \
                        "-c '#{psql_command}'")

        output = `#{command} | tail -n +2`

        $CHILD_STATUS.success? ? Success(output) : Failure(output)
      end
    end
  end
end

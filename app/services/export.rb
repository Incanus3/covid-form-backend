require 'English'
require 'open3'
require 'dry/monads'

module CovidForm
  module Services
    class Export
      include Import[:db]
      include Dry::Monads[:result]

      static_facade :perform, [:db]

      def perform
        select_sql   = db.registrations.sql_for_export
        psql_command = "\\copy (#{select_sql}) to STDOUT CSV DELIMITER ';' HEADER FORCE QUOTE *"
        db_options   = db.gateways[:default].options
        command      = ("PGPASSWORD=#{db_options[:password]} psql "         \
                        "-h #{db_options[:host]} -p #{db_options[:port]} "  \
                        "-U #{db_options[:user]} #{db_options[:database]} " \
                        "-c \"#{psql_command}\"")

        stdout, stderr, status = Open3.capture3(command)

        status.success? ? Success(stdout.lines[1..].join) : Failure(stderr)
      end
    end
  end
end

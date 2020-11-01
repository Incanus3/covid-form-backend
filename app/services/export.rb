require 'English'
require 'open3'
require 'dry/monads'
require 'app/dependencies'

module CovidForm
  module Services
    class Export
      include Import[:db]
      include Dry::Monads[:result]

      DELIMITER = ';'.freeze

      attr_private_initialize [:db, :start_date, :end_date]

      def perform
        select_sql             = db.registrations.sql_for_export(start_date, end_date)
        stdout, stderr, status = Open3.capture3(export_command_for(select_sql))

        return Failure(stderr) unless status.success?

        lines  = stdout.lines
        output =
          if lines.size < 2 || lines[0].count(DELIMITER) == lines[1].count(DELIMITER)
            # :nocov:
            stdout
            # :nocov:
          else
            # in some cases the command first prints some debugging line - remove it
            lines[1..].join
          end

        Success({ csv: output, encoding: encoding })
      end

      private

      def export_command_for(select_sql)
        psql_command = ("\\copy (#{select_sql}) to STDOUT CSV DELIMITER '#{DELIMITER}' " \
                        "ENCODING '#{encoding}' HEADER FORCE QUOTE *")

        "PGPASSWORD=#{db.options[:password]} psql "           \
          "-h #{db.options[:host]} -p #{db.options[:port]} "  \
          "-U #{db.options[:user]} #{db.options[:database]} " \
          "-c \"#{psql_command}\""
      end

      def encoding
        ENV.fetch('CSV_ENCODING', 'UTF-8')
      end
    end
  end
end

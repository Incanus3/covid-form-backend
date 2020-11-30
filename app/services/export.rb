require 'English'
require 'open3'
require 'dry/monads'
require 'app/dependencies'

module CovidForm
  module Services
    class Export
      include Import[:db]
      include Dry::Monads[:result]

      DELIMITER        = ';'.freeze
      ENCODINGS_TO_TRY = ['UTF-8', 'Windows-1250'].freeze

      attr_private_initialize [:db, :start_date, :end_date]

      def perform
        select_sql             = db.registrations.sql_for_export(start_date, end_date)
        stdout, stderr, status = Open3.capture3(export_command_for(select_sql))

        return Failure(stderr) unless status.success?

        lines = force_encoding(stdout).lines

        if lines.size > 1 && lines[0].count(DELIMITER) != lines[1].count(DELIMITER)
          lines = lines.drop(1)
        end

        output = lines.join

        Success({ csv: output, encoding: output.encoding.name })
      end

      private

      def export_command_for(select_sql)
        psql_command = ("\\copy (#{select_sql}) to STDOUT CSV DELIMITER '#{DELIMITER}' " \
                        "ENCODING '#{postgres_encoding}' HEADER FORCE QUOTE *")

        "PGPASSWORD='#{db.options[:password]}' psql "             \
          "-h '#{db.options[:host]}' -p '#{db.options[:port]}' "  \
          "-U '#{db.options[:user]}' -w '#{db.options[:database]}' " \
          "-c \"#{psql_command}\""
      end

      def postgres_encoding
        ENV.fetch('CSV_ENCODING', 'UTF-8')
      end

      def force_encoding(string)
        ENCODINGS_TO_TRY.each do |encoding|
          updated = string.clone.force_encoding(encoding)

          return updated if updated.valid_encoding?
        end
      end
    end
  end
end

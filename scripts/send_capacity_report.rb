#!/usr/bin/env ruby

APP_ROOT = File.expand_path('..', __dir__)

$LOAD_PATH.unshift APP_ROOT

require 'attr_extras'
require 'faraday'

require 'lib/env_vars'
require 'app/dependencies'
require 'app/services/capacity'

module CovidForm
  class Reporter
    DEFAULT_NUMBER_OF_DAYS = 30

    attr_private :url

    attr_private_initialize [
      :ag_cfa_id!, :pcr_cfa_id!, :token!, :log_file, env: :test, logging: true
    ] do
      # :nocov:
      env_segment = env == :production ? 'prod' : 'test'
      # :nocov:
      base_url    = "https://st#{env_segment}coviddashboard.blob.core.windows.net/crs"
      filename    = "CRS_#{pcr_cfa_id}_#{Time.now.strftime('%Y%m%d%H%M%S')}.json"
      @url        = "#{base_url}/#{filename}?#{token}"
    end

    def report(number_of_days: DEFAULT_NUMBER_OF_DAYS)
      ag_data  = data_for_report(exam_type: 'ag',  number_of_days: number_of_days)
      pcr_data = data_for_report(exam_type: 'pcr', number_of_days: number_of_days)

      send_report(pcr_data, ag_data)
    end

    private

    def send_report(pcr_data, ag_data)
      body = [
        { cfaId: pcr_cfa_id, values: pcr_data },
        { cfaId: ag_cfa_id,  values: ag_data  },
      ]

      connection.put('', JSON.pretty_generate(body))
    end

    def data_for_report(exam_type:, number_of_days:)
      capacity_service.daily_capacities_for_report(
        exam_type, Date.today, Date.today + number_of_days - 1
      )
    end

    def connection
      headers = { 'Content-Type' => 'application/json', 'x-ms-blob-type' => 'BlockBlob' }

      Faraday.new(url: url, headers: headers) do |faraday|
        # :nocov:
        if logging
          logger = log_file && Logger.new(log_file)
          faraday.response(:logger, logger, { headers: true, bodies: true })
        end
        # :nocov:
      end
    end

    def capacity_service
      @_capacity_service ||= CovidForm::Services::Capacity.new
    end
  end
end

# :nocov:
if __FILE__ == $PROGRAM_NAME
  CovidForm::Dependencies.start(:persistence)
  CovidForm::Dependencies.start(:configuration)

  reporter = CovidForm::Reporter.new(
    env:        ENV.fetch('CRS_ENV', 'test').to_sym,
    token:      ENV.fetch('CRS_TOKEN'),
    pcr_cfa_id: ENV.fetch('CRS_PCR_CFA_ID'),
    ag_cfa_id:  ENV.fetch('CRS_AG_CFA_ID'),
    log_file:   ENV.fetch('CRS_LOG_FILE', nil),
    logging:    Utils::EnvVars.fetch_bool('CRS_LOGGING', default: true),
  )

  reporter.report
end
# :nocov:

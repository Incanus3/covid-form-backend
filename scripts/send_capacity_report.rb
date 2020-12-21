#!/usr/bin/env ruby

APP_ROOT = File.expand_path('..', __dir__)

$LOAD_PATH.unshift APP_ROOT

require 'attr_extras'
require 'app/dependencies'
require 'app/services/capacity'

module CovidForm
  class Reporter
    DEFAULT_NUMBER_OF_DAYS = 30

    def send_report(number_of_days: DEFAULT_NUMBER_OF_DAYS)
      ag_data  = data_for_report(exam_type: 'ag',  number_of_days: number_of_days)
      pcr_data = data_for_report(exam_type: 'pcr', number_of_days: number_of_days)

      puts JSON.pretty_generate(ag_data)
      puts JSON.pretty_generate(pcr_data)
    end

    private

    def data_for_report(exam_type:, number_of_days:)
      capacity_service.daily_capacities_for_report(
        exam_type, Date.today, Date.today + number_of_days
      )
    end

    def capacity_service
      @_capacity_service ||= CovidForm::Services::Capacity.new
    end
  end
end

# :nocov:
if __FILE__ == $PROGRAM_NAME
  Dependencies.start(:persistence)

  reporter = CovidForm::Reporter.new

  reporter.send_report
end
# :nocov:

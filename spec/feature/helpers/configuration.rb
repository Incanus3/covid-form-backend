require 'app/configuration'
require 'app/dependencies'

module CovidForm
  module TestHelpers
    module Configuration
      Import[:db]

      DEFAULT_CONFIG_OPTIONS = {
        week_starts_on:                       1,
        open_registration_in_weeks:           0,
        close_registration_in_weeks:          100,
        daily_registration_limit:             200,
        registration_deadline_offset_minutes: 600,
        enable_registration_deadline:         false,
        allow_registration_for_weekends:      true,
      }.freeze

      def mock_config_with(**options)
        allow(CovidForm::Dependencies).to receive(:resolve).and_call_original
        allow(CovidForm::Dependencies).to receive(:resolve).with(:config).and_return(
          CovidForm::Configuration.new(:test, db, DEFAULT_CONFIG_OPTIONS.merge(options)),
        )
      end
    end
  end
end

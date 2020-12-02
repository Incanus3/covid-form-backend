module CovidForm
  module ConfigurationHelpers
    DEFAULT_CONFIG_OPTIONS = {
      daily_registration_limit:             200,
      registration_deadline_offset_minutes: 600,
      enable_registration_deadline:         false,
      allow_registration_for_weekends:      true,
    }.freeze

    def mock_config_with(**options)
      allow(CovidForm::Dependencies).to receive(:resolve).and_call_original
      allow(CovidForm::Dependencies).to receive(:resolve).with(:config)
        .and_return(DEFAULT_CONFIG_OPTIONS.merge(options))
    end
  end
end

RSpec.configure do |config|
  config.include CovidForm::ConfigurationHelpers
end

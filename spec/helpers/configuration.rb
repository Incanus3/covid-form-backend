module CovidForm
  module ConfigurationHelpers
    DEFAULT_CONFIG_OPTIONS = {
      allow_registration_for_weekends:       true,
      allow_registration_for_today_after_10: true,
      daily_registration_limit:              200,
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

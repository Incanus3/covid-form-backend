require 'rspec/collection_matchers'

# rubocop:disable Style/MethodCallWithArgsParentheses
RSpec.configure do |config|
  config.disable_monkey_patching!

  config.fail_fast = true
  config.run_all_when_everything_filtered = true

  config.filter_run_including :focus
  config.filter_run_excluding :disabled
  config.filter_run_excluding :slow
  config.filter_run_excluding block: nil

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.backtrace_exclusion_patterns = [/bundler|rack|roda|rspec|database_cleaner/]
end
# rubocop:enable Style/MethodCallWithArgsParentheses

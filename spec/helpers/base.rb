require 'rspec/collection_matchers'
require 'super_diff/rspec'

# rubocop:disable Style/MethodCallWithArgsParentheses
RSpec.configure do |config|
  config.disable_monkey_patching!

  config.fail_fast = true
  config.run_all_when_everything_filtered = true

  config.alias_example_group_to :feature, type: :feature

  config.filter_run_including :focus
  config.filter_run_excluding :disabled
  config.filter_run_excluding :slow
  # config.filter_run_excluding block: nil

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.backtrace_exclusion_patterns = [/bundler|rack|roda|rspec|database_cleaner/]

  config.example_status_persistence_file_path = File.join(APP_ROOT, 'spec', '.rspec.status')
end
# rubocop:enable Style/MethodCallWithArgsParentheses

require 'simplecov'

SimpleCov.configure do
  enable_coverage :branch

  add_filter '/spec/'

  add_group 'Application', 'app'
  add_group 'Utilities',   'lib'

  maximum_coverage_drop 3
  minimum_coverage line: 95, branch: 65
  minimum_coverage_by_file 90
end


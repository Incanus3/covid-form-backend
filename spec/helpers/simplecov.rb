require 'simplecov'

SimpleCov.configure do
  enable_coverage :branch

  add_filter '/spec/'

  add_group 'Application', 'app'
  add_group 'Utilities',   'lib'

  maximum_coverage_drop 3
  minimum_coverage line: 97, branch: 85
  minimum_coverage_by_file 95
end


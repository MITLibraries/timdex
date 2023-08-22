ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov::Formatter::LcovFormatter.config.lcov_file_name = 'coverage.lcov'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
]
SimpleCov.start('rails')

require_relative '../config/environment'
require 'rails/test_help'

VCR.configure do |config|
  config.ignore_localhost = false
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
end

module ActiveSupport
  class TestCase
    # Setup fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

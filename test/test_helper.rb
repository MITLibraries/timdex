ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'coveralls'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
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

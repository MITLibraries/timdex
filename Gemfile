source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.5'

gem 'aws-sdk-elasticsearchservice'
gem 'bootsnap', require: false
gem 'devise'
gem 'elasticsearch', '~>8.3'
gem 'faraday_middleware-aws-sigv4'
gem 'flipflop'
gem 'graphql'
gem 'jbuilder'
gem 'jwt'
gem 'lograge'
gem 'mitlibraries-theme'
gem 'opensearch-ruby'
gem 'puma'
gem 'rack-attack'
gem 'rack-cors'
gem 'rails', '~> 6.1.0'
gem 'redis'
gem 'sass-rails'
gem 'sentry-raven'
gem 'uglifier'

group :production do
  gem 'pg'
end

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'sqlite3'
end

group :development do
  gem 'annotate'
  gem 'graphiql-rails'
  gem 'listen'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'chromedriver-helper'
  gem 'climate_control'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

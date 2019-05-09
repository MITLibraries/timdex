source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.1'

gem 'aws-sdk-elasticsearchservice'
gem 'bootsnap', require: false
gem 'devise'
gem 'elasticsearch'
gem 'faraday_middleware-aws-sigv4'
gem 'jbuilder'
gem 'jwt'
gem 'lograge'
gem 'mitlibraries-theme'
gem 'puma'
gem 'rack-attack'
gem 'rack-cors'
gem 'rails', '~> 5.2'
gem 'redis'
gem 'sass-rails'
gem 'uglifier'

group :production do
  gem 'pg'
end

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'sqlite3'
  gem 'therubyracer', platforms: :ruby
end

group :development do
  gem 'annotate'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rubocop'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'chromedriver-helper'
  gem 'climate_control'
  gem 'coveralls', require: false
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

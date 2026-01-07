source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.8'

gem 'bootsnap', require: false
gem 'devise'
gem 'faraday_middleware-aws-sigv4'
gem 'flipflop'
gem 'graphql'
gem 'jwt'
gem 'lograge'
gem 'mitlibraries-theme', git: 'https://github.com/mitlibraries/mitlibraries-theme', tag: 'v1.4'
gem 'opensearch-ruby'
gem 'puma'
gem 'rack-attack'
gem 'rack-cors'
gem 'rails', '~> 7.2.0'
gem 'redis'
gem 'sass-rails'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'uglifier'

group :production do
  gem 'connection_pool', '< 3'   # 3.x requires keyword args; pin to 2.x for Rails 7.2.3
  gem 'pg'
end

group :development, :test do
  gem 'byebug'
  gem 'dotenv-rails'
  gem 'sqlite3'
end

group :development do
  gem 'annotate'
  gem 'jekyll'
  gem 'jekyll-remote-theme'
  gem 'jekyll-seo-tag'
  gem 'listen'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'climate_control'
  gem 'minitest', '< 6' # required for Rails 7.2.3
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

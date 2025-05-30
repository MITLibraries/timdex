source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.8'

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
gem 'rails', '~> 7.1.0'
gem 'redis'
gem 'sass-rails'
gem 'sentry-rails'
gem 'sentry-ruby'
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
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.0'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.4'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  gem 'shoulda-matchers', '~> 4.0'

  gem 'rspec-rails', '~> 6.1'
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'selenium-webdriver'
  gem 'webdrivers'

  gem 'rails-controller-testing'
  gem 'simplecov', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem 'websocket-client-simple'
end

# Nearest neighbor searches with vector embeddings
gem 'neighbor'
gem 'pgvector'

gem 'dotenv-rails', groups: %i[development test]

gem 'httparty'

# Markdown renderer
gem 'redcarpet'

gem 'tiktoken_ruby'

gem 'tailwindcss-rails', '~> 2.0'

# For SSO
gem 'ruby-saml'

gem 'rubocop'

gem 'kaminari'

gem 'optparse'

gem 'daemons'

# For the job queueing system.
gem 'delayed_job_active_record'

# For tracking likes/dislikes on questions/documents
gem 'acts_as_votable'

gem 'pg_search'

gem 'pundit', '~> 2.3'

gem 'bundle-audit'

gem 'brakeman'

gem 'reverse_markdown'

gem 'pager_duty-connection'

gem 'slack-ruby-client'

gem 'savon'

gem 'restforce'

gem 'omniauth-google-oauth2'

gem 'google-api-client'
gem 'googleauth'

gem 'uri', '>= 1.0.3'
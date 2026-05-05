# frozen_string_literal: true

source "https://rubygems.org"

gem "hanami", "~> 2.3.0"
gem "hanami-assets", "~> 2.3.0"
gem "hanami-controller", "~> 2.3.0"
gem "hanami-db", "~> 2.3.0"
gem "hanami-router", "~> 2.3.0"
gem "hanami-validations", "~> 2.3.0"
gem "hanami-view", "~> 2.3.0"

gem "aws-sdk-s3"
gem "dry-operation", ">= 1.0.1"
gem "dry-types", "~> 1.7"
gem "omniauth", "~> 2.1"
gem "omniauth-discord", "~> 1.2"
gem "omniauth-github", "~> 2.0"
gem "pg"
gem "puma"
gem "rake"
gem "tzinfo"
gem "ulid"

group :development do
  gem "hanami-webconsole", "~> 2.3.0"

  gem "docquet", "~> 1.2"
  gem "rubocop", "~> 1.86"
  gem "rubocop-capybara", "~> 2.22"
  gem "rubocop-performance", "~> 1.26"
  gem "rubocop-rake", "~> 0.7.1"
  gem "rubocop-rspec", "~> 3.9"
  gem "rubocop-sequel", "~> 0.4.1"
  gem "rubocop-thread_safety", "~> 0.7.3"

  gem "redcarpet", "~> 3.6"
  gem "yard", "~> 0.9.43"

  gem "debug", "~> 1.11"
  gem "ruby-lsp", "~> 0.26.9"
end

group :development, :test do
  gem "dotenv"

  gem "irb"
  gem "repl_type_completor"
end

group :cli, :development do
  gem "hanami-reloader", "~> 2.3.0"
end

group :cli, :development, :test do
  gem "hanami-rspec", "~> 2.3.0"
end

group :test do
  # Database
  gem "database_cleaner-sequel"
  gem "rom-factory"

  # Web integration
  gem "capybara"
  gem "rack-test"

  gem "simplecov", "~> 0.22.0"
end

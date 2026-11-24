# frozen_string_literal: true

source "https://rubygems.org"

gem "hanami", "3.0.2"
gem "hanami-action", "3.0.1"
gem "hanami-assets", "3.0.0"
gem "hanami-db", "3.0.0"
gem "hanami-router", "3.0.0"
gem "hanami-view", "3.0.2"

gem "aws-sdk-s3", "1.245.1"
gem "aws-sdk-sqs", "1.131.0"
gem "aws-sdk-ssm", "1.237.0"
gem "concurrent-ruby", "1.3.8"
gem "dry-operation", "1.2.0"
gem "dry-types", "1.9.2"
gem "dry-validation", "1.11.1"
gem "omniauth", "2.4.2"
gem "omniauth-discord", "1.2.0"
gem "omniauth-github", "2.0.1"
gem "omniauth-steam", "1.0.6"
# omniauth-steam -> omniauth-openid -> ruby-openid depends on these.
# Ruby 4.0 extracted them from stdlib into bundled gems that require explicit listing.
gem "cgi", "0.5.2"
gem "pg", "1.7.0"
gem "puma", "8.1.2"
gem "rake", "13.4.2"
gem "rexml", "3.4.4"
gem "tzinfo", "2.0.6"
gem "ulid", "1.4.0"

group :development do
  gem "hanami-webconsole", "3.0.0"

  gem "docquet", "1.4.0"
  gem "foxtail-tools", "0.6.1"
  gem "rubocop", "1.92.3"
  gem "rubocop-capybara", "3.1.0"
  gem "rubocop-performance", "1.27.0"
  gem "rubocop-rake", "0.7.1"
  gem "rubocop-rspec", "3.10.2"
  gem "rubocop-sequel", "0.4.1"
  gem "rubocop-thread_safety", "0.8.0"

  gem "debug", "1.11.1"
  gem "ruby-lsp", "0.26.11"
end

group :development, :test do
  gem "dotenv", "3.2.0"

  gem "irb", "1.19.0"
  gem "repl_type_completor", "0.1.18"
end

group :cli, :development do
  gem "hanami-reloader", "3.0.0"
end

group :cli, :development, :test do
  gem "hanami-rspec", "3.0.0"
end

group :test do
  # Database
  gem "database_cleaner-sequel", "2.0.2"
  gem "rom-factory", "0.14.1"

  # Web integration
  gem "capybara", "3.40.0"
  gem "rack-test", "2.3.0"

  # API contract
  gem "json_schemer", "2.5.0"

  gem "simplecov", "1.3.2"
end

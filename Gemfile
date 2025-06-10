# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in langchain.gemspec.
gemspec

group :test do
  gem "sqlite3"
end

# Development and test dependencies
group :development, :test do
  gem "rspec", "~> 3.0"
  gem "rspec-rails"
  gem "standard", ">= 1.35.1"
  gem "rubocop"
  gem "rubocop-rails-omakase", require: false
  gem "rake", "~> 13.0"
end

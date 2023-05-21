# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in langchain.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "standardrb"

# TODO: Fix this `faraday` issue where some gems are using 1.x and others are using 2.x
# Most likely everything will just need to be updated to `faraday 2.x`
gem "replicate-ruby", git: "https://github.com/andreibondarev/replicate-ruby.git", branch: "faraday-1.x"

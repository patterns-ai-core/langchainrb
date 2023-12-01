# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in langchain.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "standardrb"
# Lets add rubocop explicitly here, we are using only standardrb rules in .rubocop.yml
gem "rubocop"

# Temporary fix until https://github.com/github/graphql-client/pull/314 is merged
gem "graphql-client", git: "https://github.com/rmosolgo/graphql-client.git", branch: "start-migrating"

# test_github_tool.rb
require "dotenv/load" # make sure you have .env with GITHUB_ACCESS_TOKEN
require "./lib/langchain"

# 1. Initialize
github_tool = Langchain::Tool::Github.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])

# 2. Test fetching issues
puts "--- Testing Issues ---"
response = github_tool.execute(input: { 
  action: "list_issues", 
  owner: "rails", 
  repo: "rails", 
  limit: 3 
}.to_json)
puts response

# 3. Test reading a file
puts "\n--- Testing File Content ---"
response = github_tool.execute(input: { 
  action: "file_content", 
  owner: "andreibondarev", 
  repo: "langchainrb", 
  path: "Gemfile" 
}.to_json)
content = response.respond_to?(:content) ? response.content : response
puts content[0..100] + "..." # Print first 100 chars

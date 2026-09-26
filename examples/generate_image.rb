# frozen_string_literal: true

# Example demonstrating Langchain's unified image generation API across providers
#
# Prerequisites (set any of these):
#   export OPENAI_API_KEY="your_api_key"
#   export GOOGLE_GEMINI_API_KEY="your_api_key"
#   export GOOGLE_VERTEX_AI_PROJECT_ID="your_project_id"
#
# Run with:
#   bundle exec ruby examples/generate_image.rb

require "bundler/inline"

# Ensure dependencies for a standalone execution outside of gem install
# This will be skipped if already present in the main Gemfile
gemfile(true) do
  source "https://rubygems.org"
  gem "ruby-openai", ">= 6.3"
  gem "googleauth" # For Google Vertex AI
  gem "langchainrb", path: File.expand_path("..", __dir__)
end

require "langchainrb"
require "base64"

# Build array of available LLM providers based on environment variables
llms = []

# OpenAI
if ENV["OPENAI_API_KEY"]
  llms << {
    name: "OpenAI DALL-E 3",
    instance: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"]),
    options: {size: "1024x1024"}
  }
end

# Google Gemini
if ENV["GOOGLE_GEMINI_API_KEY"]
  llms << {
    name: "Google Gemini",
    instance: Langchain::LLM::GoogleGemini.new(api_key: ENV["GOOGLE_GEMINI_API_KEY"]),
    options: {n: 1}
  }
end

# Google Vertex AI
if ENV["GOOGLE_VERTEX_AI_PROJECT_ID"]
  region = ENV.fetch("GOOGLE_VERTEX_AI_REGION", "us-central1")
  llms << {
    name: "Google Vertex AI (Imagen)",
    instance: Langchain::LLM::GoogleVertexAI.new(
      project_id: ENV["GOOGLE_VERTEX_AI_PROJECT_ID"],
      region: region
    ),
    options: {n: 1}
  }
end

if llms.empty?
  puts "No LLM providers configured. Please set at least one of:"
  puts "  - OPENAI_API_KEY"
  puts "  - GOOGLE_GEMINI_API_KEY"
  puts "  - GOOGLE_VERTEX_AI_PROJECT_ID"
  exit 1
end

# Common prompt for all providers
PROMPT = "A minimalist illustration of a ruby gemstone on a dark background"

puts "Generating images with prompt: \"#{PROMPT}\""
puts "Using #{llms.length} provider(s)"
puts

# Demonstrate unified API - same method call works across all providers
llms.each do |llm_config|
  puts "=== #{llm_config[:name]} ==="
  
  begin
    # Unified API call - works the same for all providers
    response = llm_config[:instance].generate_image(
      prompt: PROMPT,
      **llm_config[:options]
    )
    
    # Handle different response formats
    if response.respond_to?(:image_urls) && !response.image_urls.empty?
      puts "✓ Generated #{response.image_urls.count} image(s)"
      response.image_urls.each_with_index do |url, i|
        puts "  Image #{i + 1} URL: #{url}"
      end
    elsif response.respond_to?(:image_base64s) && !response.image_base64s.empty?
      puts "✓ Generated #{response.image_base64s.count} image(s)"
      response.image_base64s.each_with_index do |data, i|
        filename = "#{llm_config[:name].downcase.gsub(/\s+/, '_')}_image_#{i + 1}.png"
        begin
          decoded_data = Base64.decode64(data)
          File.binwrite(filename, decoded_data)
          puts "  Image #{i + 1}: Saved to #{filename} (#{decoded_data.bytesize} bytes)"
        rescue => e
          puts "  Image #{i + 1}: Base64 data received (#{data.length} chars) - error saving: #{e.message}"
        end
      end
    else
      puts "✗ No images in response"
    end
  rescue => e
    puts "✗ Error: #{e.message}"
  end
  
  puts
end

puts "Summary:"
puts "- All providers use the same `generate_image` method"
puts "- Responses provide either `image_urls` or `image_base64s`"
puts "- This unified API makes it easy to switch between providers" 
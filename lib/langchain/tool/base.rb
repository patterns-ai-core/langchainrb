# frozen_string_literal: true

module Langchain::Tool
  # = Tools
  #
  # Tools are used by Agents to perform specific tasks. Basically anything is possible with enough code!
  #
  # == Available Tools
  #
  # - {Langchain::Tool::Calculator}: calculate the result of a math expression
  # - {Langchain::Tool::Database}: executes SQL queries
  # - {Langchain::Tool::FileSystem}: interacts with files
  # - {Langchain::Tool::GoogleSearch}: search on Google (via SerpAPI)
  # - {Langchain::Tool::RubyCodeInterpreter}: runs ruby code
  # - {Langchain::Tool::Weather}: gets current weather data
  # - {Langchain::Tool::Wikipedia}: search on Wikipedia
  #
  # == Usage
  #
  # 1. Pick the tools you'd like to pass to an Agent and install the gems listed under **Gem Requirements**
  #
  #     # For example to use the Calculator, GoogleSearch, and Wikipedia:
  #     gem install eqn
  #     gem install google_search_results
  #     gem install wikipedia-client
  #
  # 2. Set the environment variables listed under **ENV Requirements**
  #
  #     export SERPAPI_API_KEY=paste-your-serpapi-api-key-here
  #
  # 3. Pass the tools when Agent is instantiated.
  #
  #     agent = Langchain::Assistant.new(
  #       llm: Langchain::LLM::OpenAI.new(api_key: "YOUR_API_KEY"), # or other LLM that supports function calling (coming soon)
  #       thread: Langchain::Thread.new,
  #       tools: [
  #         Langchain::Tool::GoogleSearch.new(api_key: "YOUR_API_KEY"),
  #         Langchain::Tool::Calculator.new,
  #         Langchain::Tool::Wikipedia.new
  #       ]
  #     )
  #
  # == Adding Tools
  #
  # 1. Create a new file in lib/langchain/tool/your_tool_name.rb
  # 2. Create a class in the file that inherits from {Langchain::Tool::Base}
  # 3. Add `NAME=` and `ANNOTATIONS_PATH=` constants in your Tool class
  # 4. Implement various methods in your tool class
  # 5. Create a sidecar .json file in the same directory as your tool file annotating the methods in the Open API format
  # 6. Add your tool to the {file:README.md}
  class Base
    include Langchain::DependencyHelper

    # Returns the NAME constant of the tool
    #
    # @return [String] tool name
    def name
      self.class.const_get(:NAME)
    end

    def self.logger_options
      {
        color: :light_blue
      }
    end

    # Returns the tool as a list of OpenAI formatted functions
    #
    # @return [Hash] tool as an OpenAI tool
    def to_openai_tools
      method_annotations
    end

    # Return tool's method annotations as JSON
    #
    # @return [Hash] Tool's method annotations
    def method_annotations
      JSON.parse(
        File.read(
          self.class.const_get(:ANNOTATIONS_PATH)
        )
      )
    end
  end
end

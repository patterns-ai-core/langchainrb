# frozen_string_literal: true

module Langchain::Tool
  # = Tools
  #
  # Tools are used by Assistants to perform specific tasks. Basically anything is possible with enough code!
  #
  # == Available Tools
  #
  # - {Langchain::Tool::Calculator}: calculate the result of a math expression
  # - {Langchain::Tool::Database}: executes SQL queries
  # - {Langchain::Tool::GoogleSearch}: search on Google (via SerpAPI)
  # - {Langchain::Tool::RubyCodeInterpreter}: runs ruby code
  # - {Langchain::Tool::Weather}: gets current weather data
  # - {Langchain::Tool::Wikipedia}: search on Wikipedia
  #
  # == Usage
  #
  # 1. Pick the tools you'd like to pass to an Assistant and install the gems listed under **Gem Requirements**
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
  # 3. Pass the tools when Assistant is instantiated.
  #
  #     assistant = Langchain::Assistant.new(
  #       llm: llm,
  #       thread: thread,
  #       instructions: "You are a Meteorologist Assistant that is able to pull the weather for any location",
  #       tools: [
  #         Langchain::Tool::GoogleSearch.new(api_key: ENV["SERPAPI_API_KEY"])
  #       ]
  #     )
  #
  # == Adding Tools
  #
  # 1. Create a new file in lib/langchain/tool/your_tool_name.rb
  # 2. Create a class in the file that inherits from {Langchain::Tool::Base}
  # 3. Add `NAME=` and `DESCRIPTION=` constants in your Tool class
  # 4. Implement `execute(input:)` method in your tool class
  # 5. Add your tool to the {file:README.md}
  class Base
    include Langchain::DependencyHelper

    def initialize
      raise "Your tool must specify ANNOTATIONS_PATH constant with a path to your method annotations JSON file" unless self.class.const_defined?(:ANNOTATIONS_PATH)
    end

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

    # Returns the DESCRIPTION constant of the tool
    #
    # @return [String] tool description
    def description
      self.class.const_get(:DESCRIPTION)
    end

    # Sets the DESCRIPTION constant of the tool
    #
    # @param value [String] tool description
    def self.description(value)
      const_set(:DESCRIPTION, value.tr("\n", " ").strip)
    end

    # Instantiates and executes the tool and returns the answer
    #
    # @param input [String] input to the tool
    # @return [String] answer
    def self.execute(input:)
      warn "DEPRECATED: `#{self}.execute` is deprecated, and will be removed in the next major version."

      new.execute(input: input)
    end

    # Returns the tool as a list of OpenAI formatted functions
    #
    # @return [Hash] tool as an OpenAI tool
    def to_openai_tools
      method_annotations
    end

    # Executes the tool and returns the answer
    #
    # @param input [String] input to the tool
    # @return [String] answer
    # @raise NotImplementedError when not implemented
    def execute(input:)
      raise NotImplementedError, "Your tool must implement the `#execute(input:)` method that returns a string"
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

    # Validates the list of tools or raises an error
    #
    # @param tools [Array<Langchain::Tool>] list of tools to be used
    # @raise [ArgumentError] If any of the tools are not supported
    def self.validate_tools!(tools:)
      # Check if the tool count is equal to unique tool count
      if tools.count != tools.map(&:name).uniq.count
        raise ArgumentError, "Either tools are not unique or are conflicting with each other"
      end
    end
  end
end

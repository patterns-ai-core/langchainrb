# frozen_string_literal: true

module Langchain::Tool
  # = Tools
  #
  # Tools are used by Agents to perform specific tasks. A 'Tool' is a collection of functions ("methods").
  #
  # == Available Tools
  #
  # - {Langchain::Tool::Calculator}: calculate the result of a math expression
  # - {Langchain::Tool::Database}: executes SQL queries
  # - {Langchain::Tool::FileSystem}: interacts with the file system
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
  # 1. Create a new folder in lib/langchain/tool/your_tool_name/
  # 2. Inside of this folder create a file with a class YourToolName that inherits from {Langchain::Tool::Base}
  # 3. Add `NAME=` and `ANNOTATIONS_PATH=` constants in your Tool class
  # 4. Implement various public methods in your tool class
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

    private

    def generate_method_annotations
      # One-shot example
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/tool/prompts/generate_method_annotations.yaml")
      )
      prompt_template.format(example_method_definitions: example_method_definitions, example_method_annotations: example_method_annotations)
      # Extract the method annotations
      # Save the output to JSON file.
    end

    def example_method_definitions
      # Random tool class to be used as an example
      klass = Langchain::Tool::FileSystem
      # Get the source code of each instance method in the class
      klass.instance_methods(false).map do |i_method|
        klass.instance_method(i_method).source
      end
    end

    def example_method_annotations
      Langchain::Tool::FileSystem.new.method_annotations
    end
  end
end

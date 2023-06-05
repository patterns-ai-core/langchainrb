# frozen_string_literal: true

module Langchain::Tool
  class Base
    include Langchain::DependencyHelper

    # How to add additional Tools?
    # 1. Create a new file in lib/tool/your_tool_name.rb
    # 2. Add your tool to the TOOLS hash below
    #    "Tool::YourToolName" => "your_tool_name"
    # 3. Implement `self.execute(input:)` method in your tool class
    # 4. Add your tool to the README.md

    TOOLS = {
      "Langchain::Tool::Calculator" => "calculator",
      "Langchain::Tool::SerpApi" => "search",
      "Langchain::Tool::Wikipedia" => "wikipedia",
      "Langchain::Tool::Database" => "database"
    }

    def self.description(value)
      const_set(:DESCRIPTION, value.tr("\n", " ").strip)
    end

    # Instantiates and executes the tool and returns the answer
    # @param input [String] input to the tool
    # @return [String] answer
    def self.execute(input:)
      new.execute(input: input)
    end

    # Executes the tool and returns the answer
    # @param input [String] input to the tool
    # @return [String] answer
    def execute(input:)
      raise NotImplementedError, "Your tool must implement the `#execute(input:)` method that returns a string"
    end

    #
    # Validates the list of strings (tools) are all supported or raises an error
    # @param tools [Array<Langchain::Tool>] list of tools to be used
    #
    # @raise [ArgumentError] If any of the tools are not supported
    #
    def self.validate_tools!(tools:)
      tools.map(&:class).each do |tool_class|
        unless TOOLS.include?(tool_class.name)
          raise ArgumentError, "Tool not supported: #{tool_class.name}"
        end
      end
    end
  end
end

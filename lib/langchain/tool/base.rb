# frozen_string_literal: true

module Langchain::Tool
  class Base
    include Langchain::DependencyHelper

    # How to add additional Tools?
    # 1. Create a new file in lib/tool/your_tool_name.rb
    # 2. Create a class in the file that inherits from Langchain::Tool::Base
    # 3. Add `NAME=` and `DESCRIPTION=` constants in your Tool class
    # 4. Implement `execute(input:)` method in your tool class
    # 5. Add your tool to the README.md

    def self.description(value)
      const_set(:DESCRIPTION, value.tr("\n", " ").strip)
    end

    #
    # Instantiates and executes the tool and returns the answer
    #
    # @param input [String] input to the tool
    # @return [String] answer
    #
    def self.execute(input:)
      new.execute(input: input)
    end

    #
    # Executes the tool and returns the answer
    #
    # @param input [String] input to the tool
    # @return [String] answer
    #
    def execute(input:)
      raise NotImplementedError, "Your tool must implement the `#execute(input:)` method that returns a string"
    end

    #
    # Validates the list of tools or raises an error
    # @param tools [Array<Langchain::Tool>] list of tools to be used
    #
    # @raise [ArgumentError] If any of the tools are not supported
    #
    def self.validate_tools!(tools:)
      # Check if the tool count is equal to unique tool count
      if tools.count != tools.map { |tool| tool.class.const_get(:NAME) }.uniq.count
        raise ArgumentError, "Either tools are not unique or are conflicting with each other"
      end
    end
  end
end

# frozen_string_literal: true

module Langchain::Tool
  class Base
    include Langchain::DependencyHelper

    # How to add additional Tools?
    # 1. Create a new file in lib/tool/your_tool_name.rb
    # 2. Create a class in the file that inherits from Langchain::Tool::Base
    # 3. Implement name and description in your tool class
    # 4. Implement `self.execute(input:)` method in your tool class
    # 5. Add your tool to the README.md

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
    # Validates the list of tools or raises an error
    # @param tools [Array<Langchain::Tool>] list of tools to be used
    #
    # @raise [ArgumentError] If any of the tools are not supported
    #
    def self.validate_tools!(tools:)
      # Check if the count of tools equals the count of unique tools
      if tools.count != tools.map{|tool| Langchain::Tool.const_get(tool.class.to_s).const_get(:NAME)}.uniq.count
        raise ArgumentError, "You cannot use the same named tool twice"
      end
    end
  end
end

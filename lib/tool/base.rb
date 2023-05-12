# frozen_string_literal: true

module Tool
  class Base
    TOOLS = {
      "calculator" => "Tool::Calculator",
      "search" => "Tool::SerpApi"
    }

    # 
    # Validates the list of strings (tools) are all supported or raises an error
    # @param tools [Array<String>] list of tools to be used
    # 
    # @raise [ArgumentError] If any of the tools are not supported
    # 
    def self.validate_tools!(tools:)
      unrecognized_tools = tools - Tool::Base::TOOLS.keys 

      if unrecognized_tools.any?
        raise ArgumentError, "Unrecognized Tools: #{unrecognized_tools}" 
      end
    end
  end
end

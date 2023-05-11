# frozen_string_literal: true

module Tool
  class Base
    TOOLS = {
      "calculator" => "Tool::Calculator",
      "search" => "Tool::SerpApi"
    }

    def self.validate_tools!(tools:)
      unrecognized_tools = tools - Tool::Base::TOOLS.keys 

      if unrecognized_tools.any?
        raise ArgumentError, "Unrecognized Tools: #{unrecognized_tools}" 
      end
    end
  end
end

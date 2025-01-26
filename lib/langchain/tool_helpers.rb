# frozen_string_literal: true

module Langchain
  module ToolHelpers
    # Create a tool response
    # @param content [String, nil] The content of the tool response
    # @param image_url [String, nil] The URL of an image
    # @return [Langchain::ToolResponse] The tool response
    def tool_response(content: nil, image_url: nil)
      Langchain::ToolResponse.new(content: content, image_url: image_url)
    end
  end
end

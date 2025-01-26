# frozen_string_literal: true

module Langchain
  module ToolHelpers
    def tool_response(content: nil, image_url: nil)
      Langchain::ToolResponse.new(content: content, image_url: image_url)
    end
  end
end

# frozen_string_literal: true

module Langchain
  # ToolResponse represents the standardized output of a tool.
  # It can contain either text content or an image URL.
  class ToolResponse
    attr_reader :content, :image_url

    # Initializes a new ToolResponse.
    #
    # @param content [String] The text content of the response.
    # @param image_url [String, nil] Optional URL to an image.
    def initialize(content: nil, image_url: nil)
      raise ArgumentError, "Either content or image_url must be provided" if content.nil? && image_url.nil?

      @content = content
      @image_url = image_url
    end

    def to_s
      content.to_s
    end
  end
end

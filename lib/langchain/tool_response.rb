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

    # Wraps a raw response in a ToolResponse if it is not already one.
    #
    # @param response [String, ToolResponse] The raw response to wrap.
    # @return [ToolResponse] The wrapped response.
    def self.wrap(response)
      return response if response.is_a?(ToolResponse)

      new(content: response)
    end

    # Converts the response into a format compatible with the given LLM provider.
    #
    # @param provider_class [Class] The provider class handling the response.
    # @return [Hash] The formatted response for the provider.
    def to_api_format(provider_class)
      provider_class.format_tool_response(self)
    end

    # Checks if the response has an image URL.
    #
    # @return [Boolean] True if an image URL is present.
    def has_image?
      !image_url.nil?
    end

    # Checks if the response has text content.
    #
    # @return [Boolean] True if text content is present.
    def has_content?
      !content.nil?
    end

    def to_s
      content.to_s
    end

    def to_str
      to_s
    end

    def include?(other)
      to_s.include?(other)
    end
  end
end

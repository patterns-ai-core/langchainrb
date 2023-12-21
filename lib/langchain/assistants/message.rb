# frozen_string_literal: true

module Langchain
  class Message
    attr_reader :role, :text

    # @param role [String] The role of the message sender
    # @param text [String] The text of the message
    def initialize(role:, text:) # TODO: Implement image_file: reference (https://platform.openai.com/docs/api-reference/messages/object#messages/object-content)
      @role = role
      @text = text
    end

    # @return [String] The message as a string
    def to_s
      "#{role}: #{text}"
    end
  end
end

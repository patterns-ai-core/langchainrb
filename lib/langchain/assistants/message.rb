# frozen_string_literal: true

module Langchain
  class Message
    ROLES = [
      "assistant",
      "user",
      "tool_output"
    ].freeze

    attr_reader :role, :text

    def initialize(role:, text:) # TODO: Implement image_file: reference (https://platform.openai.com/docs/api-reference/messages/object#messages/object-content)
      raise ArgumentError, "role must be one of #{ROLES}" unless ROLES.include?(role)

      @role = role
      @text = text
    end

    def to_s
      "#{role}: #{text}"
    end
  end
end

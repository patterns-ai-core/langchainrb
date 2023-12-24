# frozen_string_literal: true

module Langchain
  class Message
    attr_reader :role, :content, :tool_calls, :tool_call_id

    ROLES = %w[
      system
      assistant
      user
      tool
    ].freeze

    # @param role [String] The role of the message
    # @param content [String] The content of the message
    # @param tool_calls [Array<Hash>] The tool calls to be made
    # @param tool_call_id [String] The ID of the tool call to be made
    def initialize(role:, content: nil, tool_calls: [], tool_call_id: nil) # TODO: Implement image_file: reference (https://platform.openai.com/docs/api-reference/messages/object#messages/object-content)
      raise ArgumentError, "Role must be one of #{ROLES.join(", ")}" unless ROLES.include?(role)

      @role = role
      # Some Tools return content as a JSON.
      @content = content.to_s
      @tool_calls = tool_calls
      @tool_call_id = tool_call_id
    end

    # @return [Hash] The message as an OpenAI API-compatible hash
    def to_openai_format
      {}.tap do |h|
        h[:role] = role
        h[:content] = content if content # Content is nil for tool calls
        h[:tool_calls] = tool_calls if tool_calls.any?
        h[:tool_call_id] = tool_call_id if tool_call_id
      end
    end

    def assistant?
      role == "assistant"
    end

    def system?
      role == "system"
    end

    def user?
      role == "user"
    end

    def tool?
      role == "tool"
    end
  end
end

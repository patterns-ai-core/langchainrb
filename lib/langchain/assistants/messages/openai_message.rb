# frozen_string_literal: true

module Langchain
  module Messages
    class OpenAIMessage < Base
      # OpenAI uses the following roles:
      ROLES = [
        "system",
        "assistant",
        "user",
        "tool"
      ].freeze

      TOOL_ROLE = "tool"

      def initialize(role:, content: nil, tool_calls: [], tool_call_id: nil) # TODO: Implement image_file: reference (https://platform.openai.com/docs/api-reference/messages/object#messages/object-content)
        raise ArgumentError, "Role must be one of #{ROLES.join(", ")}" unless ROLES.include?(role)
        raise ArgumentError, "Tool calls must be an array of hashes" unless tool_calls.is_a?(Array) && tool_calls.all? { |tool_call| tool_call.is_a?(Hash) }

        @role = role
        # Some Tools return content as a JSON hence `.to_s`
        @content = content.to_s
        @tool_calls = tool_calls
        @tool_call_id = tool_call_id
      end

      # Was this message produced by an LLM?
      #
      # @return [Boolean] true/false whether this message was produced by an LLM
      def llm?
        assistant?
      end

      # Convert the message to an OpenAI API-compatible hash
      #
      # @return [Hash] The message as an OpenAI API-compatible hash
      def to_hash
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

      def tool?
        role == "tool"
      end
    end
  end
end

module Langchain
  module Messages
    class AwsBedrockMessage < Base
      ROLES = [
        "assistant",
        "user",
        "tool_result"
      ].freeze

      TOOL_ROLE = "tool_result"

      def initialize(role:, content: nil, tool_calls: [], tool_call_id: nil)
        @role = role
        @content = content
        @tool_calls = tool_calls
        @tool_call_id = tool_call_id
      end

      # Convert the message to an AWS Bedrock API-compatible hash
      #
      # @return [Hash] The message as an AWS Bedrock API-compatible hash
      def to_hash
        {}.tap do |h|
          h[:role] = tool? ? "user" : role

          h[:content] = if tool?
            [
              {
                type: "tool_result",
                tool_use_id: tool_call_id,
                content: content
              }
            ]
          elsif tool_calls.any?
            tool_calls
          else
            content
          end
        end
      end

      # Check if the message is a tool call
      #
      # @return [Boolean] true/false whether this message is a tool call
      def tool?
        role == "tool_result"
      end

      # AWS Bedrock does not implement system prompts
      def system?
        false
      end

      # Check if the message came from an LLM
      #
      # @return [Boolean] true/false whether this message was produced by an LLM
      def assistant?
        role == "assistant"
      end

      # Check if the message came from an LLM
      #
      # @return [Boolean] true/false whether this message was produced by an LLM
      def llm?
        assistant?
      end
    end
  end
end

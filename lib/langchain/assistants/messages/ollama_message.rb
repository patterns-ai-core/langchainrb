# frozen_string_literal: true

module Langchain
  module Messages
    class OllamaMessage < Base
      # OpenAI uses the following roles:
      ROLES = [
        "system",
        "assistant",
        "user",
        "tool"
      ].freeze

      TOOL_ROLE = "tool"

      # Initialize a new OpenAI message
      #
      # @param [String] The role of the message
      # @param [String] The content of the message
      # @param [Array<Hash>] The tool calls made in the message
      # @param [String] The ID of the tool call
      def initialize(role:, content: nil, tool_calls: [], tool_call_id: nil)
        raise ArgumentError, "Role must be one of #{ROLES.join(", ")}" unless ROLES.include?(role)
        raise ArgumentError, "Tool calls must be an array of hashes" unless tool_calls.is_a?(Array) && tool_calls.all? { |tool_call| tool_call.is_a?(Hash) }

        @role = role
        # Some Tools return content as a JSON hence `.to_s`
        @content = content.to_s
        @tool_calls = tool_calls
        @tool_call_id = tool_call_id
      end

      def to_s
        send(:"to_#{role}_message_string")
      end

      def to_system_message_string
        content
      end

      def to_user_message_string
        "[INST] #{content}[/INST]"
      end

      def to_tool_message_string
        "[TOOL_RESULTS] #{content}[/TOOL_RESULTS]"
      end

      def to_assistant_message_string
        if tool_calls.any?
          %("[TOOL_CALLS] #{tool_calls}")
        else
          content
        end
      end

      # Check if the message came from an LLM
      #
      # @return [Boolean] true/false whether this message was produced by an LLM
      def llm?
        assistant?
      end

      # Check if the message came from an LLM
      #
      # @return [Boolean] true/false whether this message was produced by an LLM
      def assistant?
        role == "assistant"
      end

      # Check if the message are system instructions
      #
      # @return [Boolean] true/false whether this message are system instructions
      def system?
        role == "system"
      end

      # Check if the message is a tool call
      #
      # @return [Boolean] true/false whether this message is a tool call
      def tool?
        role == "tool"
      end
    end
  end
end

# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class Base
          # Build the chat parameters for the LLM
          #
          # @param messages [Array] The messages
          # @param instructions [String] The system instructions
          # @param tools [Array] The tools to use
          # @param tool_choice [String] The tool choice
          # @param parallel_tool_calls [Boolean] Whether to make parallel tool calls
          # @return [Hash] The chat parameters
          def build_chat_params(
            messages:,
            instructions:,
            tools:,
            tool_choice:,
            parallel_tool_calls:
          )
            raise NotImplementedError, "Subclasses must implement build_chat_params"
          end

          # Extract the tool call information from the tool call hash
          #
          # @param tool_call [Hash] The tool call hash
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            raise NotImplementedError, "Subclasses must implement extract_tool_call_args"
          end

          # Build a message for the LLM
          #
          # @param role [String] The role of the message
          # @param content [String] The content of the message
          # @param image_url [String] The image URL
          # @param tool_calls [Array] The tool calls
          # @param tool_call_id [String] The tool call ID
          # @return [Messages::Base] The message
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            raise NotImplementedError, "Subclasses must implement build_message"
          end

          # Does this adapter accept messages with role="system"?
          #
          # @return [Boolean] Whether the adapter supports system messages
          def support_system_message?
            raise NotImplementedError, "Subclasses must implement support_system_message?"
          end

          # Role name used to return the tool output
          #
          # @return [String] The tool role
          def tool_role
            raise NotImplementedError, "Subclasses must implement tool_role"
          end
        end
      end
    end
  end
end

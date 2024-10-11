# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class Base
          # Build the chat parameters for the LLM
          #
          # @param tools [Array] The tools to use
          # @param instructions [String] The system instructions
          # @param messages [Array] The messages
          # @param tool_choice [String] The tool choice
          # @return [Hash] The chat parameters
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
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
        end
      end
    end
  end
end

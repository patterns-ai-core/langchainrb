# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class Ollama < Base
          # Build the chat parameters for the Ollama LLM
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
            Langchain.logger.warn "WARNING: `parallel_tool_calls:` is not supported by Ollama currently"
            Langchain.logger.warn "WARNING: `tool_choice:` is not supported by Ollama currently"

            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
            end
            params
          end

          # Build an Ollama message
          #
          # @param role [String] The role of the message
          # @param content [String] The content of the message
          # @param image_url [String] The image URL
          # @param tool_calls [Array] The tool calls
          # @param tool_call_id [String] The tool call ID
          # @return [Messages::OllamaMessage] The Ollama message
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            Messages::OllamaMessage.new(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the OpenAI tool call hash
          #
          # @param tool_call [Hash] The tool call hash
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")

            function_name = tool_call.dig("function", "name")
            tool_name, method_name = function_name.split("__")

            tool_arguments = tool_call.dig("function", "arguments")
            tool_arguments = if tool_arguments.is_a?(Hash)
              Langchain::Utils::HashTransformer.symbolize_keys(tool_arguments)
            else
              JSON.parse(tool_arguments, symbolize_names: true)
            end

            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          # Build the tools for the Ollama LLM
          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
          end

          # Get the allowed assistant.tool_choice values for Ollama
          def allowed_tool_choices
            ["auto", "none"]
          end

          def tool_role
            Messages::OllamaMessage::TOOL_ROLE
          end

          def support_system_message?
            Messages::OllamaMessage::ROLES.include?("system")
          end

          private

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end
        end
      end
    end
  end
end

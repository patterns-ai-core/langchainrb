# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class OpenAI < Base
          # Build the chat parameters for the OpenAI LLM
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
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
              params[:parallel_tool_calls] = parallel_tool_calls
            end
            params
          end

          # Build a OpenAI message
          #
          # @param role [String] The role of the message
          # @param content [String] The content of the message
          # @param image_url [String] The image URL
          # @param tool_calls [Array] The tool calls
          # @param tool_call_id [String] The tool call ID
          # @return [Messages::OpenAIMessage] The OpenAI message
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            Messages::OpenAIMessage.new(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)
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

          # Build the tools for the OpenAI LLM
          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end

          # Get the allowed assistant.tool_choice values for OpenAI
          def allowed_tool_choices
            ["auto", "none"]
          end

          # Get the available tool names for OpenAI
          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
          end

          def tool_role
            Messages::OpenAIMessage::TOOL_ROLE
          end

          def support_system_message?
            Messages::OpenAIMessage::ROLES.include?("system")
          end

          private

          def build_tool_choice(choice)
            case choice
            when "auto"
              choice
            else
              {"type" => "function", "function" => {"name" => choice}}
            end
          end
        end
      end
    end
  end
end

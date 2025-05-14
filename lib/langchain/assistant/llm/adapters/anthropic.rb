# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class Anthropic < Base
          # Build the chat parameters for the Anthropic API
          #
          # @param messages [Array<Hash>] The messages
          # @param instructions [String] The system instructions
          # @param tools [Array<Hash>] The tools to use
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
              params[:tool_choice] = build_tool_choice(tool_choice, parallel_tool_calls)
            end
            params[:system] = instructions if instructions
            params
          end

          # Build an Anthropic message
          #
          # @param role [String] The role of the message
          # @param content [String] The content of the message
          # @param image_url [String] The image URL
          # @param tool_calls [Array<Hash>] The tool calls
          # @param tool_call_id [String] The tool call ID
          # @return [Messages::AnthropicMessage] The Anthropic message
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            Messages::AnthropicMessage.new(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the Anthropic tool call hash
          #
          # @param tool_call [Hash] The tool call hash, format: {"type"=>"tool_use", "id"=>"toolu_01TjusbFApEbwKPRWTRwzadR", "name"=>"news_retriever__get_top_headlines", "input"=>{"country"=>"us", "page_size"=>10}}], "stop_reason"=>"tool_use"}
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")
            function_name = tool_call.dig("name")
            tool_name, method_name = function_name.split("__")
            tool_arguments = tool_call.dig("input").transform_keys(&:to_sym)
            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          # Build the tools for the Anthropic API
          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_anthropic_format }.flatten
          end

          # Get the allowed assistant.tool_choice values for Anthropic
          def allowed_tool_choices
            ["auto", "any"]
          end

          # Get the available tool function names for Anthropic
          #
          # @param tools [Array<Hash>] The tools
          # @return [Array<String>] The tool function names
          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:name) }
          end

          def tool_role
            Messages::AnthropicMessage::TOOL_ROLE
          end

          def support_system_message?
            Messages::AnthropicMessage::ROLES.include?("system")
          end

          private

          def build_tool_choice(choice, parallel_tool_calls)
            tool_choice_object = {disable_parallel_tool_use: !parallel_tool_calls}

            case choice
            when "auto"
              tool_choice_object[:type] = "auto"
            when "any"
              tool_choice_object[:type] = "any"
            else
              tool_choice_object[:type] = "tool"
              tool_choice_object[:name] = choice
            end

            tool_choice_object
          end
        end
      end
    end
  end
end

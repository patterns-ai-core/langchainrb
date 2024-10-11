# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class GoogleGemini < Base
          # Build the chat parameters for the Google Gemini LLM
          #
          # @param tools [Array] The tools to use
          # @param instructions [String] The system instructions
          # @param messages [Array] The messages
          # @param tool_choice [String] The tool choice
          # @return [Hash] The chat parameters
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:system] = instructions if instructions
              params[:tool_choice] = build_tool_config(tool_choice)
            end
            params
          end

          # Build a Google Gemini message
          #
          # @param role [String] The role of the message
          # @param content [String] The content of the message
          # @param image_url [String] The image URL
          # @param tool_calls [Array] The tool calls
          # @param tool_call_id [String] The tool call ID
          # @return [Messages::GoogleGeminiMessage] The Google Gemini message
          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            warn "Image URL is not supported by Google Gemini" if image_url

            Messages::GoogleGeminiMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the Google Gemini tool call hash
          #
          # @param tool_call [Hash] The tool call hash, format: {"functionCall"=>{"name"=>"weather__execute", "args"=>{"input"=>"NYC"}}}
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("functionCall", "name")
            function_name = tool_call.dig("functionCall", "name")
            tool_name, method_name = function_name.split("__")
            tool_arguments = tool_call.dig("functionCall", "args").transform_keys(&:to_sym)
            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          # Build the tools for the Google Gemini LLM
          #
          # @param tools [Array<Langchain::Tool::Base>] The tools
          # @return [Array] The tools in Google Gemini format
          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_google_gemini_format }.flatten
          end

          # Get the allowed assistant.tool_choice values for Google Gemini
          def allowed_tool_choices
            ["auto", "none"]
          end

          # Get the available tool names for Google Gemini
          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:name) }
          end

          def tool_role
            Langchain::Messages::GoogleGeminiMessage::TOOL_ROLE
          end

          private

          def build_tool_config(choice)
            case choice
            when "auto"
              {function_calling_config: {mode: "auto"}}
            when "none"
              {function_calling_config: {mode: "none"}}
            else
              {function_calling_config: {mode: "any", allowed_function_names: [choice]}}
            end
          end
        end
      end
    end
  end
end

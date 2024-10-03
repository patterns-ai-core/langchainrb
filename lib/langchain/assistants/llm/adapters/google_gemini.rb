module Langchain
  class Assistant
    module LLM
      module Adapters
        class GoogleGemini < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:system] = instructions if instructions
              params[:tool_choice] = build_tool_config(tool_choice)
            end
            params
          end

          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            warn "Image URL is not supported by Google Gemini" if image_url

            Langchain::Messages::GoogleGeminiMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
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

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_google_gemini_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:name) }
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

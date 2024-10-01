module Langchain
  class Assistant
    module LLM
      module Adapters
        class MistralAI < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
            end
            params
          end

          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            warn "Image URL is not supported by MistralAI currently" if image_url

            Langchain::Messages::MistralAIMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
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

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
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

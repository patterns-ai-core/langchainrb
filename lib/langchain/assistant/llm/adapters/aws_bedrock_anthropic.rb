# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      module Adapters
        class AwsBedrockAnthropic < Anthropic
          private

          # @param [String] choice
          # @param [Boolean] _parallel_tool_calls
          # @return [Hash]
          def build_tool_choice(choice, _parallel_tool_calls)
            # Aws Bedrock hosted Anthropic does not support parallel tool calls
            Langchain.logger.warn "WARNING: parallel_tool_calls is not supported by AWS Bedrock Anthropic currently"

            tool_choice_object = {}

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

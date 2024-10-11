# frozen_string_literal: true

module Langchain
  class Assistant
    module Messages
      class GoogleGeminiMessage < Base
        # Google Gemini uses the following roles:
        ROLES = [
          "user",
          "model",
          "function"
        ].freeze

        TOOL_ROLE = "function"

        # Initialize a new Google Gemini message
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

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def llm?
          model?
        end

        # Convert the message to a Google Gemini API-compatible hash
        #
        # @return [Hash] The message as a Google Gemini API-compatible hash
        def to_hash
          {}.tap do |h|
            h[:role] = role
            h[:parts] = if function?
              [{
                functionResponse: {
                  name: tool_call_id,
                  response: {
                    name: tool_call_id,
                    content: content
                  }
                }
              }]
            elsif tool_calls.any?
              tool_calls
            else
              [{text: content}]
            end
          end
        end

        # Google Gemini does not implement system prompts
        def system?
          false
        end

        # Check if the message is a tool call
        #
        # @return [Boolean] true/false whether this message is a tool call
        def tool?
          function?
        end

        # Check if the message is a tool call
        #
        # @return [Boolean] true/false whether this message is a tool call
        def function?
          role == "function"
        end

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def model?
          role == "model"
        end
      end
    end
  end
end

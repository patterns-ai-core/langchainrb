# frozen_string_literal: true

module Langchain
  class Assistant
    module Messages
      class AnthropicMessage < Base
        ROLES = [
          "assistant",
          "user",
          "tool_result"
        ].freeze

        TOOL_ROLE = "tool_result"

        # Initialize a new Anthropic message
        #
        # @param role [String] The role of the message
        # @param content [String] The content of the message
        # @param tool_calls [Array<Hash>] The tool calls made in the message
        # @param tool_call_id [String] The ID of the tool call
        def initialize(
          role:,
          content: nil,
          image_url: nil,
          tool_calls: [],
          tool_call_id: nil
        )
          raise ArgumentError, "Role must be one of #{ROLES.join(", ")}" unless ROLES.include?(role)
          raise ArgumentError, "Tool calls must be an array of hashes" unless tool_calls.is_a?(Array) && tool_calls.all? { |tool_call| tool_call.is_a?(Hash) }

          @role = role
          # Some Tools return content as a JSON hence `.to_s`
          @content = content.to_s
          @image_url = image_url
          @tool_calls = tool_calls
          @tool_call_id = tool_call_id
        end

        # Convert the message to an Anthropic API-compatible hash
        #
        # @return [Hash] The message as an Anthropic API-compatible hash
        def to_hash
          if assistant?
            assistant_hash
          elsif tool?
            tool_hash
          elsif user?
            user_hash
          end
        end

        # Convert the message to an Anthropic API-compatible hash
        #
        # @return [Hash] The message as an Anthropic API-compatible hash, with the role as "assistant"
        def assistant_hash
          {
            role: "assistant",
            content: [
              {
                type: "text",
                text: content
              }
            ].concat(tool_calls)
          }
        end

        # Convert the message to an Anthropic API-compatible hash
        #
        # @return [Hash] The message as an Anthropic API-compatible hash, with the role as "user"
        def tool_hash
          {
            role: "user",
            # TODO: Tool can also return images
            # https://docs.anthropic.com/en/docs/build-with-claude/tool-use#handling-tool-use-and-tool-result-content-blocks
            content: [
              {
                type: "tool_result",
                tool_use_id: tool_call_id,
                content: content
              }
            ]
          }
        end

        # Convert the message to an Anthropic API-compatible hash
        #
        # @return [Hash] The message as an Anthropic API-compatible hash, with the role as "user"
        def user_hash
          {
            role: "user",
            content: build_content_array
          }
        end

        # Builds the content value for the message hash
        # @return [Array<Hash>] An array of content hashes
        def build_content_array
          content_details = []

          if content && !content.empty?
            content_details << {
              type: "text",
              text: content
            }
          end

          if image
            content_details << {
              type: "image",
              source: {
                type: "base64",
                data: image.base64,
                media_type: image.mime_type
              }
            }
          end

          content_details
        end

        # Check if the message is a tool call
        #
        # @return [Boolean] true/false whether this message is a tool call
        def tool?
          role == "tool_result"
        end

        # Anthropic does not implement system prompts
        def system?
          false
        end

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def assistant?
          role == "assistant"
        end

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def llm?
          assistant?
        end
      end
    end
  end
end

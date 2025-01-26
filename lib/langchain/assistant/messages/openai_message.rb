# frozen_string_literal: true

module Langchain
  class Assistant
    module Messages
      class OpenAIMessage < Base
        # OpenAI uses the following roles:
        ROLES = [
          "system",
          "assistant",
          "user",
          "tool"
        ].freeze

        TOOL_ROLE = "tool"

        # Initialize a new OpenAI message
        #
        # @param role [String] The role of the message
        # @param content [String] The content of the message
        # @param image_url [String] The URL of the image
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

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def llm?
          assistant?
        end

        # Convert the message to an OpenAI API-compatible hash
        #
        # @return [Hash] The message as an OpenAI API-compatible hash
        def to_hash
          if assistant?
            assistant_hash
          elsif system?
            system_hash
          elsif tool?
            tool_hash
          elsif user?
            user_hash
          end
        end

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def assistant?
          role == "assistant"
        end

        # Check if the message are system instructions
        #
        # @return [Boolean] true/false whether this message are system instructions
        def system?
          role == "system"
        end

        # Check if the message is a tool call
        #
        # @return [Boolean] true/false whether this message is a tool call
        def tool?
          role == "tool"
        end

        def user?
          role == "user"
        end

        # Convert the message to an OpenAI API-compatible hash
        # @return [Hash] The message as an OpenAI API-compatible hash, with the role as "assistant"
        def assistant_hash
          if tool_calls.any?
            {
              role: "assistant",
              tool_calls: tool_calls
            }
          else
            {
              role: "assistant",
              content: build_content_array
            }
          end
        end

        # Convert the message to an OpenAI API-compatible hash
        # @return [Hash] The message as an OpenAI API-compatible hash, with the role as "system"
        def system_hash
          {
            role: "system",
            content: build_content_array
          }
        end

        # Convert the message to an OpenAI API-compatible hash
        # @return [Hash] The message as an OpenAI API-compatible hash, with the role as "tool"
        def tool_hash
          {
            role: "tool",
            tool_call_id: tool_call_id,
            content: build_content_array
          }
        end

        # Convert the message to an OpenAI API-compatible hash
        # @return [Hash] The message as an OpenAI API-compatible hash, with the role as "user"
        def user_hash
          {
            role: "user",
            content: build_content_array
          }
        end

        # Builds the content value for the message hash
        # @return [Array<Hash>] An array of content hashes, with keys :type and :text or :image_url.
        def build_content_array
          content_details = []
          if content && !content.empty?
            content_details << {
              type: "text",
              text: content
            }
          end

          if image_url
            content_details << {
              type: "image_url",
              image_url: {
                url: image_url
              }
            }
          end
          content_details
        end
      end
    end
  end
end

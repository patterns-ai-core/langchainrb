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

        # Mime types of the files that can be referenced by a Cloud Storage (gs://) URI
        FILE_URI_MIME_TYPES = {
          "png" => "image/png",
          "jpg" => "image/jpeg",
          "jpeg" => "image/jpeg",
          "webp" => "image/webp",
          "heic" => "image/heic",
          "heif" => "image/heif",
          "gif" => "image/gif",
          "pdf" => "application/pdf"
        }.freeze

        # Initialize a new Google Gemini message
        #
        # @param role [String] The role of the message
        # @param content [String] The content of the message
        # @param image_url [String] The URL of the image to include in the message: an http(s) URL, sent inline, or a Cloud Storage gs:// URI, sent by reference
        # @param tool_calls [Array<Hash>] The tool calls made in the message
        # @param tool_call_id [String] The ID of the tool call
        def initialize(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
          raise ArgumentError, "Role must be one of #{ROLES.join(", ")}" unless ROLES.include?(role)
          raise ArgumentError, "Tool calls must be an array of hashes" unless tool_calls.is_a?(Array) && tool_calls.all? { |tool_call| tool_call.is_a?(Hash) }

          @role = role
          # Some Tools return content as a JSON hence `.to_s`
          @content = content.is_a?(Array) ? content : content.to_s
          @image_url = image_url
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
          if tool?
            tool_hash
          elsif model?
            model_hash
          elsif user?
            user_hash
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

        # Check if the message is a user call
        #
        # @return [Boolean] true/false whether this message is a user call
        def user?
          role == "user"
        end

        # Check if the message is a tool call
        #
        # @return [Boolean] true/false whether this message is a tool call
        def function?
          role == "function"
        end

        # Convert the message to an GoogleGemini API-compatible hash
        # @return [Hash] The message as an GoogleGemini API-compatible hash, with the role as "model"
        def model_hash
          {
            role: role,
            parts: build_parts
          }
        end

        # Convert the message to an GoogleGemini API-compatible hash
        # @return [Hash] The message as an GoogleGemini API-compatible hash, with the role as "function"
        def tool_hash
          if tool_call_id.is_a?(Array)
            return {
              role: role,
              parts: tool_call_id.zip(content).map do |id, result|
                {
                  functionResponse: {
                    name: id,
                    response: {
                      name: id,
                      content: result
                    }
                  }
                }
              end
            }
          end

          {
            role: role,
            parts: [{
              functionResponse: {
                name: tool_call_id,
                response: {
                  name: tool_call_id,
                  content: content
                }
              }
            }]
          }
        end

        # Convert the message to an GoogleGemini API-compatible hash
        # @return [Hash] The message as an GoogleGemini API-compatible hash, with the role as "user"
        def user_hash
          {
            role: role,
            parts: build_parts
          }
        end

        # Builds the part value for the message hash
        # @return [Array<Hash>] An array of content hashes of the text and image, or of the tool calls if present
        def build_parts
          return tool_calls if tool_calls.any?
          return [{text: content}] unless image_url

          parts = []
          parts << {text: content} unless content.empty?
          parts << image_part
          parts
        end

        # Builds the part of the image: a gs:// URI is passed by reference, other URLs are downloaded and sent inline
        # @return [Hash] The image part
        def image_part
          if image_url.start_with?("gs://")
            {fileData: {mimeType: file_uri_mime_type, fileUri: image_url}}
          else
            {inlineData: {mimeType: image.mime_type, data: image.base64}}
          end
        end

        # Check if the message came from an LLM
        #
        # @return [Boolean] true/false whether this message was produced by an LLM
        def model?
          role == "model"
        end

        private

        def file_uri_mime_type
          extension = File.extname(URI.parse(image_url).path).delete_prefix(".").downcase
          FILE_URI_MIME_TYPES.fetch(extension) do
            raise ArgumentError, "Cannot infer the mime type of #{image_url}; supported extensions: #{FILE_URI_MIME_TYPES.keys.join(", ")}"
          end
        end
      end
    end
  end
end

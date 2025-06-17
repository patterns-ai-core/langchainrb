# frozen_string_literal: true

module Langchain::LLM::Response
  class GoogleVertexAIResponse < BaseResponse
    # Imagen responses place image bytes in predictions list
    # Each prediction may include {"bytes": "BASE64"} or nested keys.
    def image_base64s
      Array(raw_response["predictions"]).map do |pred|
        pred["bytes"] || pred.dig("image", "image_bytes") || pred.dig("image", "imageBytes")
      end.compact
    end

    alias_method :image_blobs, :image_base64s

    # Other methods not supported for image response
    def chat_completion; nil; end
    def embedding; nil; end
    def embeddings; []; end
    def prompt_tokens; nil; end
    def completion_tokens; nil; end
    def total_tokens; nil; end
  end
end 
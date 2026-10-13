# frozen_string_literal: true

module Langchain::LLM::Response
  class GoogleGeminiResponse < BaseResponse
    def initialize(raw_response, model: nil)
      super
    end

    # The model's answer, from every text part. A function call or a thought summary (`"thought": true`)
    # can come before the text, and a long answer can be split over several text parts.
    def chat_completion
      texts = parts.select { |part| part.key?("text") && !part["thought"] }.map { |part| part["text"] }
      texts.join unless texts.empty?
    end

    def role
      raw_response.dig("candidates", 0, "content", "role")
    end

    # The function call parts, wherever they are. The model often explains what it's about to do in a
    # text part before the call.
    def tool_calls
      parts.select { |part| part.key?("functionCall") }
    end

    def embedding
      embeddings.first
    end

    def embeddings
      if raw_response.key?("embedding")
        [raw_response.dig("embedding", "values")]
      else
        [raw_response.dig("predictions", 0, "embeddings", "values")]
      end
    end

    def prompt_tokens
      raw_response.dig("usageMetadata", "promptTokenCount")
    end

    def completion_tokens
      raw_response.dig("usageMetadata", "candidatesTokenCount")
    end

    def total_tokens
      raw_response.dig("usageMetadata", "totalTokenCount")
    end

    private

    def parts
      Array(raw_response.dig("candidates", 0, "content", "parts")).grep(Hash)
    end
  end
end

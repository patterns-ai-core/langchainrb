# frozen_string_literal: true

module Langchain::LLM
  class GoogleGeminiResponse < BaseResponse
    def initialize(raw_response, model: nil)
      super
    end

    def chat_completion
      raw_response.dig("candidates", 0, "content", "parts", 0, "text")
    end

    def role
      raw_response.dig("candidates", 0, "content", "role")
    end

    def tool_calls
      if raw_response.dig("candidates", 0, "content") && raw_response.dig("candidates", 0, "content", "parts", 0).has_key?("functionCall")
        raw_response.dig("candidates", 0, "content", "parts")
      else
        []
      end
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
  end
end

# frozen_string_literal: true

module Langchain::LLM
  class OllamaResponse < BaseResponse
    def initialize(raw_response, model: nil, prompt_tokens: nil)
      @prompt_tokens = prompt_tokens
      super(raw_response, model: model)
    end

    def created_at
      Time.parse(raw_response.dig("created_at")) if raw_response.dig("created_at")
    end

    def chat_completion
      raw_response.dig("message", "content")
    end

    def completion
      raw_response.dig("response")
    end

    def completions
      [completion].compact
    end

    def embedding
      embeddings.first
    end

    def embeddings
      raw_response&.dig("embeddings") || []
    end

    def role
      "assistant"
    end

    def prompt_tokens
      raw_response.fetch("prompt_eval_count", 0) if done?
    end

    def completion_tokens
      raw_response.dig("eval_count") if done?
    end

    def total_tokens
      prompt_tokens + completion_tokens if done?
    end

    def tool_calls
      Array(raw_response.dig("message", "tool_calls"))
    end

    private

    def done?
      !!raw_response["done"]
    end
  end
end

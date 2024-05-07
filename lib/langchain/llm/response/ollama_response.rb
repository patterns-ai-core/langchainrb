# frozen_string_literal: true

module Langchain::LLM
  class OllamaResponse < BaseResponse
    def initialize(raw_response, model: nil, prompt_tokens: nil)
      @prompt_tokens = prompt_tokens
      super(raw_response, model: model)
    end

    def created_at
      if raw_response.dig("created_at")
        Time.parse(raw_response.dig("created_at"))
      end
    end

    def chat_completion
      raw_response.dig("message", "content")
    end

    def completion
      completions.first
    end

    def completions
      if raw_response.is_a?(String)
        [{"message" => raw_response}]
      elsif raw_response.is_a?(Hash)
        [raw_response]
      else
        warn "[ollama] Unexpected response type: #{raw_response.class}"
        []
      end
    end

    def embedding
      embeddings.first
    end

    def embeddings
      [raw_response&.dig("embedding")]
    end

    def role
      "assistant"
    end

    def prompt_tokens
      raw_response.dig("prompt_eval_count")
    end

    def completion_tokens
      raw_response.dig("eval_count")
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end
  end
end

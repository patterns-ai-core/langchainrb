# frozen_string_literal: true

module Langchain::LLM
  class MistralAIResponse < BaseResponse
    def model
      raw_response["model"]
    end

    def chat_completion
      chat_completions.dig(0, "message", "content")
    end

    def chat_completions
      raw_response.dig("choices")
    end

    def tool_calls
      chat_completions.dig(0, "message", "tool_calls") || []
    end

    def role
      raw_response.dig("choices", 0, "message", "role")
    end

    def embedding
      raw_response.dig("data", 0, "embedding")
    end

    def prompt_tokens
      raw_response.dig("usage", "prompt_tokens")
    end

    def total_tokens
      raw_response.dig("usage", "total_tokens")
    end

    def completion_tokens
      raw_response.dig("usage", "completion_tokens")
    end

    def created_at
      if raw_response.dig("created_at")
        Time.at(raw_response.dig("created_at"))
      end
    end
  end
end

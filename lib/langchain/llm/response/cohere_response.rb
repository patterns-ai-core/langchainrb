# frozen_string_literal: true

module Langchain::LLM
  class CohereResponse < BaseResponse
    def embedding
      embeddings.first
    end

    def embeddings
      raw_response.dig("embeddings")
    end

    def completions
      raw_response.dig("generations")
    end

    def completion
      completions&.dig(0, "text")
    end

    def tool_calls
      raw_response.dig("message", "tool_calls")
    end

    def chat_completion
      raw_response.dig("message", "content", 0, "text")
    end

    def role
      raw_response.dig("message", "role")
    end

    def prompt_tokens
      raw_response.dig("usage", "billed_units", "input_tokens")
    end

    def completion_tokens
      raw_response.dig("usage", "billed_units", "output_tokens")
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end
  end
end

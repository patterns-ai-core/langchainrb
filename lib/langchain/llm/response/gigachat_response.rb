# frozen_string_literal: true

module Langchain::LLM
  class GigachatResponse < BaseResponse
    def model
      raw_response["model"]
    end

    def created_at
      if raw_response.dig("created")
        Time.at(raw_response.dig("created"))
      end
    end

    def completion
      completions&.dig(0, "message", "content")
    end

    def role
      completions&.dig(0, "message", "role")
    end

    def chat_completion
      completion
    end

    def tool_calls
      if chat_completions.dig(0, "message").has_key?("function_call")
        chat_completions.dig(0, "message", "function_call")
      else
        []
      end
    end

    def embedding
      embeddings&.first
    end

    def completions
      raw_response.dig("choices")
    end

    def chat_completions
      raw_response.dig("choices")
    end

    def embeddings
      raw_response.dig("data")&.map { |datum| datum.dig("embedding") }
    end

    def prompt_tokens
      raw_response.dig("usage", "prompt_tokens")
    end

    def completion_tokens
      raw_response.dig("usage", "completion_tokens")
    end

    def total_tokens
      raw_response.dig("usage", "total_tokens")
    end
  end
end

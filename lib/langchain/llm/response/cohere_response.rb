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

    def chat_completion
      raw_response.dig("text")
    end

    def role
      raw_response.dig("chat_history").last["role"]
    end

    def prompt_tokens
      raw_response.dig("meta", "billed_units", "input_tokens")
    end

    def completion_tokens
      raw_response.dig("meta", "billed_units", "output_tokens")
    end
  end
end

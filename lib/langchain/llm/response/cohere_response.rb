# frozen_string_literal: true

module Langchain::LLM
  class CohereResponse < BaseResponse
    def first_embedding
      embeddings.first
    end

    def embeddings
      raw_response.dig("embeddings")
    end

    def completions
      raw_response.dig("generations")
    end

    def first_completion_text
      completions&.dig(0, "text")
    end
  end
end

# frozen_string_literal: true

module Langchain::LLM
  class LlamaCppResponse < BaseResponse
    def embedding
      embeddings
    end

    def embeddings
      raw_response.embeddings
    end
  end
end

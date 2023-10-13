# frozen_string_literal: true

module Langchain::LLM
  class HuggingFaceResponse < BaseResponse
    def embeddings
      [raw_response]
    end

    def first_embedding
      embeddings.first
    end
  end
end

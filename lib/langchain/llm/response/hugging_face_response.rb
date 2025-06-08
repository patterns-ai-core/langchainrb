# frozen_string_literal: true

module Langchain::LLM::Response
  class HuggingFaceResponse < BaseResponse
    def embeddings
      [raw_response]
    end

    def embedding
      embeddings.first
    end
  end
end

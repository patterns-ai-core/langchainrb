# frozen_string_literal: true

module Langchain::LLM
  class OllamaResponse < BaseResponse
    def initialize(raw_response, model: nil, prompt_tokens: nil)
      @prompt_tokens = prompt_tokens
      super(raw_response, model: model)
    end

    def completion
      raw_response.first
    end

    def completions
      raw_response.is_a?(String) ? [raw_response] : []
    end

    def embedding
      embeddings.first
    end

    def embeddings
      [raw_response&.dig("embedding")]
    end
  end
end

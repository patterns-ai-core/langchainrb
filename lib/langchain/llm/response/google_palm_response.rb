# frozen_string_literal: true

module Langchain::LLM
  class GooglePalmResponse < BaseResponse
    attr_reader :prompt_tokens

    def initialize(raw_response, model: nil, prompt_tokens: nil)
      @prompt_tokens = prompt_tokens
      super(raw_response, model: model)
    end

    def completion
      completions&.dig(0, "output")
    end

    def embedding
      embeddings.first
    end

    def completions
      raw_response.dig("candidates")
    end

    def chat_completion
      chat_completions&.dig(0, "content")
    end

    def chat_completions
      raw_response.dig("candidates")
    end

    def embeddings
      [raw_response.dig("embedding", "value")]
    end
  end
end

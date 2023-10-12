# frozen_string_literal: true

module Langchain::LLM
  class GooglePalmResponse < BaseResponse
    attr_reader :prompt_tokens

    def initialize(raw_response, model: nil, prompt_tokens: nil)
      @prompt_tokens = prompt_tokens
      super(raw_response, model: model)
    end

    def first_completion_text
      completions&.dig(0, "output")
    end

    def first_embedding
      embeddings.first
    end

    def completions
      raw_response.dig("candidates")
    end

    def first_chat_completion_text
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

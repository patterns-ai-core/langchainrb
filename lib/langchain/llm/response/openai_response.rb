# frozen_string_literal: true

module Langchain::LLM
  class OpenAIResponse < BaseResponse
    attr_reader :raw_response

    def model
      raw_response["model"]
    end

    def type
      return options[:type] if options[:type]

      is_embedding? ? "embedding" : raw_response.dig("object")
    end

    def completions
      raw_response.dig("choices")&.map { |choice| choice.dig("message") }
    end

    def embeddings
      raw_response.dig("data")&.map { |datum| datum.dig("embedding") }
    end

    def value
      is_embedding? ? embeddings.first : completions.first.dig("content")
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

    private

    def is_embedding?
      raw_response.dig("object") == "list"
    end
  end
end

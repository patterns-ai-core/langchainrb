# frozen_string_literal: true

module Langchain::LLM::Response
  class GooglePalm < Base
    def model
      options[:model]
    end

    def type
      options[:type]
    end

    def completions
      raw_response.dig("candidates")&.map do |candidate|
        is_chat_completion? ?
          {"role" => candidate.dig("author"), "content" => candidate.dig("content")} :
          {"role" => "assistant", "content" => candidate.dig("output")}
      end
    end

    def embeddings
      [raw_response.dig("embedding", "value")]
    end

    def value
      is_embedding? ? embeddings.first : completions.first.dig("content")
    end

    def prompt_tokens
      options[:prompt_tokens]
    end

    def completion_tokens
      options[:completion_tokens]
    end

    def total_tokens
      options[:total_tokens]
    end

    private

    def is_embedding?
      type == "embedding"
    end

    def is_chat_completion?
      type == "chat.completion"
    end
  end
end

# frozen_string_literal: true

module Langchain::LLM
  class AI21Response < BaseResponse
    def completions
      raw_response.dig(:completions)
    end

    def completion
      completions.dig(0, :data, :text)
    end

    def chat_completion
      raw_response.dig(:choices, 0, :message, :content)
    end

    def prompt_tokens
      raw_response.dig(:usage, :prompt_tokens).to_i
    end

    def completion_tokens
      raw_response.dig(:usage, :completion_tokens).to_i
    end

    def total_tokens
      raw_response.dig(:usage, :total_tokens).to_i
    end

    def role
      raw_response.dig(:choices, 0, :message, :role)
    end
  end
end

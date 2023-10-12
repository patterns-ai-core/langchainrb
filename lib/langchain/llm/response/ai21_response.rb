# frozen_string_literal: true

module Langchain::LLM
  class AI21Response < BaseResponse
    def completions
      raw_response.dig(:completions)
    end

    def first_completion_text
      completions.dig(0, :data, :text)
    end
  end
end

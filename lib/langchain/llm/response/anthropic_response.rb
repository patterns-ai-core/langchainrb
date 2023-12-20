# frozen_string_literal: true

module Langchain::LLM
  class AnthropicResponse < BaseResponse
    def model
      raw_response.dig("model")
    end

    def completion
      completions.first
    end

    def completions
      [raw_response.dig("completion")]
    end

    def stop_reason
      raw_response.dig("stop_reason")
    end

    def stop
      raw_response.dig("stop")
    end

    def log_id
      raw_response.dig("log_id")
    end
  end
end

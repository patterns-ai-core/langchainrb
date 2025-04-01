# frozen_string_literal: true

module Langchain::LLM
  class AwsBedrockAmazonResponse < BaseResponse
    def completion
      raw_response.dig("output", "message", "content", 0, "text")
    end

    def chat_completion
      completion
    end

    def chat_completions
      completions
    end

    def completions
      nil
    end

    def stop_reason
      raw_response.dig("stopReason")
    end

    def prompt_tokens
      raw_response.dig("usage", "inputTokens").to_i
    end

    def completion_tokens
      raw_response.dig("usage", "outputTokens").to_i
    end

    def total_tokens
      raw_response.dig("usage", "totalTokens").to_i
    end
  end
end

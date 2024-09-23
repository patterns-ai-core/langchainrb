# frozen_string_literal: true

module Langchain::LLM
  class AwsBedrockMetaResponse < BaseResponse
    def completion
      completions.first
    end

    def completions
      [raw_response.dig("generation")]
    end

    def stop_reason
      raw_response.dig("stop_reason")
    end

    def prompt_tokens
      raw_response.dig("prompt_token_count").to_i
    end

    def completion_tokens
      raw_response.dig("generation_token_count").to_i
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end
  end
end

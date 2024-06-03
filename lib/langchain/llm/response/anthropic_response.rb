# frozen_string_literal: true

module Langchain::LLM
  class AnthropicResponse < BaseResponse
    def model
      raw_response.dig("model")
    end

    def completion
      completions.first
    end

    def chat_completion
      chat_completion = chat_completions.find { |h| h["type"] == "text" }
      chat_completion&.dig("text")
    end

    def tool_calls
      tool_call = chat_completions.find { |h| h["type"] == "tool_use" }
      tool_call ? [tool_call] : []
    end

    def chat_completions
      raw_response.dig("content")
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

    def prompt_tokens
      raw_response.dig("usage", "input_tokens").to_i
    end

    def completion_tokens
      raw_response.dig("usage", "output_tokens").to_i
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end

    def role
      raw_response.dig("role")
    end
  end
end

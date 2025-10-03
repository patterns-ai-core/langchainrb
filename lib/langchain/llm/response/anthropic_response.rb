# frozen_string_literal: true

module Langchain::LLM::Response
  class AnthropicResponse < BaseResponse
    def model
      raw_response[:model]
    end

    def completion
      completions.first
    end

    def chat_completion
      chat_completion = chat_completions.find { |h| h[:type] == :text }
      chat_completion && chat_completion[:text]
    end

    def tool_calls
      tool_call = chat_completions.find { |h| h[:type] == :tool_use }
      tool_call ? [tool_call.to_h] : []
    end

    def chat_completions
      raw_response[:content]
    end

    def completions
      [raw_response[:completion]]
    end

    def stop_reason
      raw_response[:stop_reason]
    end

    def stop_sequence
      raw_response[:stop_sequence]
    end

    def log_id
      raw_response[:id]
    end

    def prompt_tokens
      raw_response[:usage][:input_tokens].to_i
    end

    def completion_tokens
      raw_response[:usage][:output_tokens].to_i
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end

    def role
      raw_response[:role].to_s
    end
  end
end

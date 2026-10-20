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
      chat_completion = chat_completions&.find { |h| h[:type].to_s == "text" }
      chat_completion && chat_completion[:text]
    end

    def tool_calls
      chat_completions&.select { |h| h[:type].to_s == "tool_use" }&.map(&:to_h) || []
    end

    # The thinking and redacted_thinking blocks, which must be passed back unchanged
    # in the assistant turn of a tool-use loop
    def thinking_blocks
      chat_completions&.select { |h| %w[thinking redacted_thinking].include?(h[:type].to_s) }&.map(&:to_h) || []
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
      usage = raw_response[:usage]
      # Anthropic reports tokens read from or written to the prompt cache apart from input_tokens
      usage[:input_tokens].to_i + usage[:cache_read_input_tokens].to_i + usage[:cache_creation_input_tokens].to_i
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

# frozen_string_literal: true

module Langchain::LLM::Response
  # Response of the AWS Bedrock Converse API, with string keys:
  #   {"output" => {"message" => {"role" => "assistant", "content" => [{"text" => "..."}]}}, "stop_reason" => "end_turn", "usage" => {...}}
  class AwsBedrockConverseResponse < BaseResponse
    def chat_completion
      texts = content_blocks.filter_map { |block| block["text"] }
      texts.join unless texts.empty?
    end

    def chat_completions
      content_blocks
    end

    def completion
      chat_completion
    end

    def role
      raw_response.dig("output", "message", "role")
    end

    # @return [Array<Hash>] The toolUse blocks: {"tool_use_id" => "...", "name" => "...", "input" => {...}}
    def tool_calls
      content_blocks.filter_map { |block| block["tool_use"] }
    end

    def stop_reason
      raw_response.dig("stop_reason")
    end

    # Includes the prompt-cache read and write tokens, which Bedrock reports apart from input_tokens
    def prompt_tokens
      usage = raw_response.dig("usage") || {}
      usage["input_tokens"].to_i + usage["cache_read_input_tokens"].to_i + usage["cache_write_input_tokens"].to_i
    end

    def completion_tokens
      raw_response.dig("usage", "output_tokens").to_i
    end

    def total_tokens
      raw_response.dig("usage", "total_tokens") || (prompt_tokens + completion_tokens)
    end

    private

    def content_blocks
      Array(raw_response.dig("output", "message", "content"))
    end
  end
end

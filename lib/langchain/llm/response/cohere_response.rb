# frozen_string_literal: true

module Langchain::LLM::Response
  class CohereResponse < BaseResponse
    def embedding
      embeddings.first
    end

    # The v2 Embed API returns {"float" => [[...]]}, the v1 API a plain array.
    def embeddings
      embeddings = raw_response.dig("embeddings")
      embeddings.is_a?(Hash) ? embeddings["float"] : embeddings
    end

    def completions
      raw_response.dig("generations")
    end

    def completion
      completions&.dig(0, "text")
    end

    def chat_completion
      content = message&.dig("content")
      return raw_response.dig("text") unless content

      content.select { |block| block["type"] == "text" }.map { |block| block["text"] }.join
    end

    def role
      message&.dig("role") || raw_response.dig("chat_history")&.last&.dig("role")
    end

    def tool_calls
      message&.dig("tool_calls") || []
    end

    def prompt_tokens
      billed_units&.dig("input_tokens")
    end

    def completion_tokens
      billed_units&.dig("output_tokens")
    end

    private

    # The v2 Chat API returns the reply as a "message" hash; an error body has a "message" string.
    def message
      raw_response["message"] if raw_response["message"].is_a?(Hash)
    end

    # v2 responses report usage under "usage", v1 responses under "meta".
    def billed_units
      raw_response.dig("usage", "billed_units") || raw_response.dig("meta", "billed_units")
    end
  end
end

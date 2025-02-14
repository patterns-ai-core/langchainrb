# frozen_string_literal: true

module Langchain::LLM
  class OpenAIResponse < BaseResponse
    def model
      raw_response["model"]
    end

    def created_at
      if raw_response.dig("created")
        Time.at(raw_response.dig("created"))
      end
    end

    def completion
      completions&.dig(0, "message", "content")
    end

    def role
      completions&.dig(0, "message", "role")
    end

    def chat_completion
      completion
    end

    def tool_calls
      if chat_completions.dig(0, "message").has_key?("tool_calls")
        chat_completions.dig(0, "message", "tool_calls")
      else
        []
      end
    end

    def embedding
      embeddings&.first
    end

    def completions
      raw_response.dig("choices")
    end

    def chat_completions
      raw_response.dig("choices")
    end

    def embeddings
      raw_response.dig("data")&.map { |datum| datum.dig("embedding") }
    end

    def prompt_tokens
      raw_response.dig("usage", "prompt_tokens")
    end

    def completion_tokens
      raw_response.dig("usage", "completion_tokens")
    end

    def total_tokens
      raw_response.dig("usage", "total_tokens")
    end

    # List models
    def format_display_name(model_id)
      name = model_id.dup
      name = name.gsub(/^gpt-/, "GPT ")
        .gsub(/^o1-/, "O1 ")
        .gsub(/^chatgpt-/, "ChatGPT ")
        .tr("-", " ")
        .split(" ")
        .map(&:capitalize)
        .join(" ")

      name = "#{name} (Legacy)" if model_id.include?("0613")
      name
    end

    def models
      raw_response.dig("data")&.map do |model|
        ModelInfo.new(
          id: model["id"],
          created_at: Time.at(model["created"]),
          display_name: format_display_name(model["id"]),
          provider: "openai",
          metadata: {
            object: model["object"],
            owned_by: model["owned_by"]
          }
        )
      end || []
    end

    def model_ids
      models.map(&:id)
    end

    def created_dates
      models.map(&:created_at)
    end

    def display_names
      models.map(&:display_name)
    end

    def provider
      "OpenAI"
    end
  end
end

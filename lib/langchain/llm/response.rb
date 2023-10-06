# frozen_string_literal: true

module Langchain::LLM
  class Response < OpenStruct
    def success?
      !error?
    end

    def error?
      error.present?
    end

    def value
      (type == "embedding") ? values.first : values.first.dig("content")
    end
  end
end

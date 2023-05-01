# frozen_string_literal: true

module LLM
  class Base
    attr_reader :client

    # Currently supported LLMs
    # TODO: Add support for HuggingFace and other LLMs
    LLMS = {
      openai: "OpenAI",
      cohere: "Cohere"
    }.freeze

    def default_dimension
      self.class.const_get("DEFAULTS").dig(:dimension)
    end
  end
end
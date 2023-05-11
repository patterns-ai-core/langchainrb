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

    # Ensure that the LLM value passed in is supported
    # @param llm [Symbol] The LLM to use
    def self.validate_llm!(llm:)
      # TODO: Fix so this works when `llm` value is a string instead of a symbol
      unless LLM::Base::LLMS.keys.include?(llm)
        raise ArgumentError, "LLM must be one of #{LLM::Base::LLMS.keys}"
      end
    end
  end
end
# frozen_string_literal: true

module Langchain
  module LLM
    autoload :Base, "langchain/llm/base"
    autoload :Cohere, "langchain/llm/cohere"
    autoload :GooglePalm, "langchain/llm/google_palm"
    autoload :HuggingFace, "langchain/llm/hugging_face"
    autoload :OpenAI, "langchain/llm/openai"
    autoload :Replicate, "langchain/llm/replicate"

    extend self

    # Currently supported LLMs
    BUILTIN = {
      cohere: "Cohere",
      google_palm: "GooglePalm",
      huggingface: "HuggingFace",
      openai: "OpenAI",
      replicate: "Replicate"
    }.freeze

    def build(llm, api_key)
      unless supported?(llm)
        raise ArgumentError, "LLM must be one of #{self::BUILTIN.keys}"
      end

      const_get(self::BUILTIN.fetch(llm)).new(api_key: api_key)
    end

    def supported?(llm)
      BUILTIN.key?(llm.to_sym)
    end
  end
end

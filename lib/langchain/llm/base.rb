# frozen_string_literal: true

module Langchain::LLM
  class Base
    include Langchain::DependencyHelper

    attr_reader :client

    # Currently supported LLMs
    LLMS = {
      cohere: "Cohere",
      google_palm: "GooglePalm",
      huggingface: "HuggingFace",
      openai: "OpenAI",
      replicate: "Replicate"
    }.freeze

    def default_dimension
      self.class.const_get(:DEFAULTS).dig(:dimension)
    end

    # Method supported by an LLM that generates a response for a given chat-style prompt
    def chat(...)
      raise NotImplementedError, "#{self.class.name} does not support chat"
    end

    # Method supported by an LLM that completes a given prompt
    def complete(...)
      raise NotImplementedError, "#{self.class.name} does not support completion"
    end

    # Method supported by an LLM that generates an embedding for a given text or array of texts
    def embed(...)
      raise NotImplementedError, "#{self.class.name} does not support generating embeddings"
    end

    # Method supported by an LLM that summarizes a given text
    def summarize(...)
      raise NotImplementedError, "#{self.class.name} does not support summarization"
    end

    def self.build(llm, api_key)
      Langchain::LLM.const_get(self::LLMS.fetch(llm)).new(api_key: api_key)
    end
  end
end

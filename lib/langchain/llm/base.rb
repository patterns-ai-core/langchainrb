# frozen_string_literal: true

module Langchain::LLM
  class Base
    include Langchain::DependencyHelper

    attr_reader :client

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
  end
end

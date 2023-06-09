# frozen_string_literal: true

module Langchain::LLM
  # A LLM is a language model consisting of a neural network with many parameters (typically billions of weights or more), trained on large quantities of unlabeled text using self-supervised learning or semi-supervised learning.
  #
  # Langchain.rb provides a common interface to interact with all supported LLMs:
  #
  # - {Langchain::LLM::AI21}
  # - {Langchain::LLM::Cohere}
  # - {Langchain::LLM::GooglePalm}
  # - {Langchain::LLM::HuggingFace}
  # - {Langchain::LLM::OpenAI}
  # - {Langchain::LLM::Replicate}
  #
  # @abstract
  class Base
    include Langchain::DependencyHelper

    # A client for communicating with the LLM
    attr_reader :client

    def default_dimension
      self.class.const_get(:DEFAULTS).dig(:dimension)
    end

    #
    # Generate a chat completion for a given prompt. Parameters will depend on the LLM
    #
    # @raise NotImplementedError if not supported by the LLM
    def chat(...)
      raise NotImplementedError, "#{self.class.name} does not support chat"
    end

    #
    # Generate a completion for a given prompt. Parameters will depend on the LLM.
    #
    # @raise NotImplementedError if not supported by the LLM
    def complete(...)
      raise NotImplementedError, "#{self.class.name} does not support completion"
    end

    #
    # Generate an embedding for a given text. Parameters depends on the LLM.
    #
    # @raise NotImplementedError if not supported by the LLM
    #
    def embed(...)
      raise NotImplementedError, "#{self.class.name} does not support generating embeddings"
    end

    #
    # Generate a summary for a given text. Parameters depends on the LLM.
    #
    # @raise NotImplementedError if not supported by the LLM
    #
    def summarize(...)
      raise NotImplementedError, "#{self.class.name} does not support summarization"
    end
  end
end

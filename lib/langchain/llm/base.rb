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
    # Generate a chat completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @param params parameters LLM-specific parameters (if any) for chat
    # @return [String] The chat completion
    # @raise NotImplementedError if not supported by the LLM
    #
    def chat(prompt:, **params)
      raise NotImplementedError, "#{self.class.name} does not support chat"
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params parameters LLM-specific parameters (if any) for complete
    # @return [String] The completion
    # @raise NotImplementedError if not supported by the LLM
    #
    def complete(prompt:, **params)
      raise NotImplementedError, "#{self.class.name} does not support completion"
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param params parameters LLM-specific parameters (if any) for embed
    # @raise NotImplementedError if not supported by the LLM
    #
    def embed(text:, **params)
      raise NotImplementedError, "#{self.class.name} does not support generating embeddings"
    end

    #
    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    # @raise NotImplementedError if not supported by the LLM
    #
    def summarize(text:)
      raise NotImplementedError, "#{self.class.name} does not support summarization"
    end
  end
end

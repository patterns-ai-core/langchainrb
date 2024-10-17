# frozen_string_literal: true

module Langchain::LLM
  class ApiError < StandardError; end

  # A LLM is a language model consisting of a neural network with many parameters (typically billions of weights or more), trained on large quantities of unlabeled text using self-supervised learning or semi-supervised learning.
  #
  # Langchain.rb provides a common interface to interact with all supported LLMs:
  #
  # - {Langchain::LLM::AI21}
  # - {Langchain::LLM::Anthropic}
  # - {Langchain::LLM::Azure}
  # - {Langchain::LLM::Cohere}
  # - {Langchain::LLM::GoogleGemini}
  # - {Langchain::LLM::GoogleVertexAI}
  # - {Langchain::LLM::HuggingFace}
  # - {Langchain::LLM::LlamaCpp}
  # - {Langchain::LLM::OpenAI}
  # - {Langchain::LLM::Replicate}
  #
  # @abstract
  class Base
    include Langchain::DependencyHelper

    # A client for communicating with the LLM
    attr_accessor :client

    # Default LLM options. Can be overridden by passing `default_options: {}` to the Langchain::LLM::* constructors.
    attr_reader :defaults

    # Ensuring backward compatibility after https://github.com/patterns-ai-core/langchainrb/pull/586
    # TODO: Delete this method later
    def default_dimension
      default_dimensions
    end

    # Returns the number of vector dimensions used by DEFAULTS[:chat_model]
    #
    # @return [Integer] Vector dimensions
    def default_dimensions
      self.class.const_get(:DEFAULTS).dig(:dimensions)
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

    #
    # Returns an instance of Langchain::LLM::Parameters::Chat
    #
    def chat_parameters(params = {})
      @chat_parameters ||= Langchain::LLM::Parameters::Chat.new(
        parameters: params
      )
    end
  end
end

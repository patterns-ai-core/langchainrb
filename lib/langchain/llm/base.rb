# frozen_string_literal: true

module Langchain::LLM
  class ApiError < StandardError; end

  # A LLM is a language model consisting of a neural network with many parameters (typically billions of weights or more), trained on large quantities of unlabeled text using self-supervised learning or semi-supervised learning.
  #
  # Langchain.rb provides a common interface to interact with all supported LLMs:
  #
  # - {Langchain::LLM::AI21}
  # - {Langchain::LLM::Azure}
  # - {Langchain::LLM::Cohere}
  # - {Langchain::LLM::GooglePalm}
  # - {Langchain::LLM::GoogleVertexAi}
  # - {Langchain::LLM::HuggingFace}
  # - {Langchain::LLM::LlamaCpp}
  # - {Langchain::LLM::OpenAI}
  # - {Langchain::LLM::Replicate}
  #
  # @abstract
  class Base
    include Langchain::DependencyHelper

    # A client for communicating with the LLM
    attr_reader :client

    UNIFIED_CHAT_SCHEMA = {
      # Either "messages" or "prompt" is required
      messages: {},
      model: {},
      prompt: {},

      # Allows to force the model to produce specific output format.
      response_format: {},

      stop: {}, # multiple types (e.g. OpenAI allows Array, null)
      stream: {}, # Enable streaming

      max_tokens: {}, # Range: [1, context_length)
      temperature: {}, # Range: [0, 2]
      top_p: {}, # Range: (0, 1]
      top_k: {}, # Range: [1, Infinity) Not available for OpenAI models
      frequency_penalty: {}, # Range: [-2, 2]
      presence_penalty: {}, # Range: [-2, 2]
      repetition_penalty: {}, # Range: (0, 2]
      seed: {}, # OpenAI only

      # Function-calling
      tools: {},
      tool_choice: {},

      # Additional optional parameters
      logit_bias: {}
    }

    # Ensuring backward compatibility after https://github.com/patterns-ai-core/langchainrb/pull/586
    # TODO: Delete this method later
    def default_dimension
      default_dimensions
    end

    # Returns the number of vector dimensions used by DEFAULTS[:chat_completion_model_name]
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
    # @returns UnifiedParameters for the chat API of the LLM.
    #
    def chat_parameters(params = {})
      @chat_parameters ||= ::Langchain::LLM::UnifiedParameters.new(
        schema: UNIFIED_CHAT_SCHEMA,
        parameters: params
      )
    end
  end
end

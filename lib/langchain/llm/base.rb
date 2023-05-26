# frozen_string_literal: true

module Langchain
  module LLM
    class Base
      attr_reader :client

      # Currently supported LLMs
      # TODO: Add support for HuggingFace and other LLMs
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

      # Ensure that the LLM value passed in is supported
      # @param llm [Symbol] The LLM to use
      def self.validate_llm!(llm:)
        # TODO: Fix so this works when `llm` value is a string instead of a symbol
        unless LLM::Base::LLMS.key?(llm)
          raise ArgumentError, "LLM must be one of #{LLM::Base::LLMS.keys}"
        end
      end
    end
  end
end
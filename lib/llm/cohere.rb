# frozen_string_literal: true

require "cohere"

module LLM
  class Cohere < Base

    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "base",
      embeddings_model_name: "small",
      dimension: 1024
    }.freeze

    def initialize(api_key:)
      @client = ::Cohere::Client.new(api_key: api_key)
    end

    # Generate an embedding for a given text
    # @param text [String] The text to generate an embedding for
    # @return [Hash] The embedding
    def embed(text:)
      response = client.embed(
        texts: [text],
        model: DEFAULTS[:embeddings_model_name],
      )
      response.dig("embeddings").first
    end

    # Generate a completion for a given prompt
    # @param prompt [String] The prompt to generate a completion for
    # @return [Hash] The completion
    def complete(prompt:)
      response = client.generate(
        prompt: prompt,
        temperature: DEFAULTS[:temperature],
        model: DEFAULTS[:completion_model_name],
      )
      response.dig("generations").first.dig("text")
    end

    alias_method :generate_completion, :complete
    alias_method :generate_embedding, :embed
  end
end
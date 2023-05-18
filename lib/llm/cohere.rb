# frozen_string_literal: true

module LLM
  class Cohere < Base
    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "base",
      embeddings_model_name: "small",
      dimension: 1024
    }.freeze

    def initialize(api_key:)
      depends_on "cohere-ruby"
      require "cohere"

      @client = ::Cohere::Client.new(api_key: api_key)
    end

    # Generate an embedding for a given text
    # @param text [String] The text to generate an embedding for
    # @return [Hash] The embedding
    def embed(text:)
      response = client.embed(
        texts: [text],
        model: DEFAULTS[:embeddings_model_name]
      )
      response.dig("embeddings").first
    end

    # Generate a completion for a given prompt
    # @param prompt [String] The prompt to generate a completion for
    # @return [Hash] The completion
    def complete(prompt:, **params)
      default_params = {
        prompt: prompt,
        temperature: DEFAULTS[:temperature],
        model: DEFAULTS[:completion_model_name]
      }

      if params[:stop_sequences]
        default_params[:stop_sequences] = params.delete(:stop_sequences)
      end

      default_params.merge!(params)

      response = client.generate(**default_params)
      response.dig("generations").first.dig("text")
    end

    # Cohere does not have a dedicated chat endpoint, so instead we call `complete()`
    def chat(...)
      complete(...)
    end

    alias_method :generate_completion, :complete
    alias_method :generate_embedding, :embed
  end
end

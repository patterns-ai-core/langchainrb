# frozen_string_literal: true

module LLM
  class Replicate < Base
    DEFAULTS = {
      temperature: 0.01, # Minimum accepted value
      completion_model_name: "vicuna-13b",
      embeddings_model_name: "all-mpnet-base-v2",
      dimension: 384
    }.freeze

    # Intialize the Replicate LLM
    # @param api_key [String] The API key to use
    def initialize(api_key:)
      depends_on "replicate-ruby"
      require "replicate-ruby"

      Replicate.configure do |config|
        config.api_token = api_key
      end

      @client = ::Replicate.client
    end

    # Generate an embedding for a given text
    # @param text [String] The text to generate an embedding for
    # @return [Hash] The embedding
    def embed(text:)
      model = Replicate.client.retrieve_model(DEFAULTS[:embeddings_model_name], version: :latest)

      response = model.predict(prompt: { input: text })
      response.dig("embeddings").first
    end

    # Generate a completion for a given prompt
    # @param prompt [String] The prompt to generate a completion for
    # @return [Hash] The completion
    def complete(prompt:, **params)
      model = Replicate.client.retrieve_model(DEFAULTS[:completion_model_name], version: :latest)

      response = model.predict(prompt: { prompt: prompt })
      response.dig("generations").first.dig("text")
    end

    # Cohere does not have a dedicated chat endpoint, so instead we call `complete()`
    def chat(...)
      complete(...)
    end

    alias_method :generate_embedding, :embed
  end
end

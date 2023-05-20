# frozen_string_literal: true

module LLM
  class Replicate < Base
    DEFAULTS = {
      temperature: 0.01, # Minimum accepted value
      completion_model_name: "replicate/vicuna-13b",
      embeddings_model_name: "creatorrr/all-mpnet-base-v2",
      dimension: 384
    }.freeze

    # Intialize the Replicate LLM
    # @param api_key [String] The API key to use
    def initialize(api_key:)
      depends_on "replicate-ruby"
      require "replicate"

      ::Replicate.configure do |config|
        config.api_token = api_key
      end

      @client = ::Replicate.client
    end

    # Generate an embedding for a given text
    # @param text [String] The text to generate an embedding for
    # @return [Hash] The embedding
    def embed(text:)
      response = embeddings_model.predict(input: text)
      
      until response.finished? do
        response.refetch
        sleep(1)
      end

      response.output
    end

    # Generate a completion for a given prompt
    # @param prompt [String] The prompt to generate a completion for
    # @return [Hash] The completion
    def complete(prompt:, **params)
      response = completion_model.predict(prompt: prompt)

      until response.finished? do
        response.refetch
        sleep(1)
      end

      # Response comes back as an array of strings, e.g.: ["Hi", "how ", "are ", "you?"]
      # The first array element is missing a space at the end, so we add it manually
      response.output[0] += " "

      response.output.join
    end

    # Cohere does not have a dedicated chat endpoint, so instead we call `complete()`
    def chat(...)
      complete(...)
    end

    alias_method :generate_embedding, :embed

    private

    def completion_model
      @completion_model ||= client.retrieve_model(DEFAULTS[:completion_model_name]).latest_version
    end

    def embeddings_model
      @embeddings_model ||= client.retrieve_model(DEFAULTS[:embeddings_model_name]).latest_version
    end
  end
end

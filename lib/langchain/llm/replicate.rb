# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around Replicate.com LLM provider
  #
  # Gem requirements:
  #     gem "replicate-ruby", "~> 0.2.2"
  #
  # Usage:
  #     llm = Langchain::LLM::Replicate.new(api_key: ENV["REPLICATE_API_KEY"])
  class Replicate < Base
    DEFAULTS = {
      # TODO: Figure out how to send the temperature to the API
      temperature: 0.01, # Minimum accepted value
      # TODO: Design the interface to pass and use different models
      completion_model: "replicate/vicuna-13b",
      embedding_model: "creatorrr/all-mpnet-base-v2",
      dimensions: 384
    }.freeze

    #
    # Intialize the Replicate LLM
    #
    # @param api_key [String] The API key to use
    #
    def initialize(api_key:, default_options: {})
      depends_on "replicate-ruby", req: "replicate"

      ::Replicate.configure do |config|
        config.api_token = api_key
      end

      @client = ::Replicate.client
      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Langchain::LLM::ReplicateResponse] Response object
    #
    def embed(text:)
      response = embeddings_model.predict(input: text)

      until response.finished?
        response.refetch
        sleep(0.1)
      end

      Langchain::LLM::ReplicateResponse.new(response, model: @defaults[:embedding_model])
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @return [Langchain::LLM::ReplicateResponse] Response object
    #
    def complete(prompt:, **params)
      response = completion_model.predict(prompt: prompt)

      until response.finished?
        response.refetch
        sleep(0.1)
      end

      Langchain::LLM::ReplicateResponse.new(response, model: @defaults[:completion_model])
    end

    #
    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    #
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(
        prompt: prompt,
        temperature: @defaults[:temperature],
        # Most models have a context length of 2048 tokens (except for the newest models, which support 4096).
        max_tokens: 2048
      )
    end

    alias_method :generate_embedding, :embed

    private

    def completion_model
      @completion_model ||= client.retrieve_model(@defaults[:completion_model]).latest_version
    end

    def embeddings_model
      @embeddings_model ||= client.retrieve_model(@defaults[:embedding_model]).latest_version
    end
  end
end

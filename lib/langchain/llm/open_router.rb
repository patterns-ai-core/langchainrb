# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Open Router APIs: https://openrouter.ai/docs
  #
  # Gem requirements:
  #    gem "open_router"
  #
  # Usage:
  #    llm = Langchain::LLM::OpenRouter.new(
  #      api_key: ENV["OPENROUTER_API_KEY"],
  #      default_options: {}
  #    )
  class OpenRouter < Base
    DEFAULTS = {
      temperature: 0.0,
      chat_model: "openrouter/auto",
      embedding_model: "openrouter/auto"
    }.freeze

    attr_reader :defaults

    def initialize(api_key:, default_options: {})
      depends_on "open_router"

      @client = ::OpenRouter::Client.new(access_token: api_key)
      @defaults = DEFAULTS.merge(default_options)

      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        providers: {default: []},
        transforms: {default: []},
        extras: {default: {}}
      )
    end

    def chat(params = {})
      parameters = chat_parameters.to_params(params)
      messages = parameters.delete(:messages)

      # Ensure default values for providers, transforms, extras
      parameters[:providers] ||= []
      parameters[:transforms] ||= []
      parameters[:extras] ||= {}

      response = client.complete(
        messages,
        model: parameters[:model],
        providers: parameters[:providers],
        transforms: parameters[:transforms],
        extras: parameters[:extras]
      )

      Langchain::LLM::OpenRouterResponse.new(response)
    end

    def embed(text:, model: nil)
      raise NotImplementedError, "Open Router does not support embeddings yet"
    end

    def models
      client.models
    end
  end
end

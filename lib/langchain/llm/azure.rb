# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Azure OpenAI Service APIs: https://learn.microsoft.com/en-us/azure/ai-services/openai/
  #
  # Gem requirements:
  #    gem "ruby-openai", "~> 6.3.0"
  #
  # Usage:
  #    openai = Langchain::LLM::Azure.new(api_key:, llm_options: {}, embedding_deployment_url: chat_deployment_url:)
  #
  class Azure < OpenAI
    attr_reader :embed_client
    attr_reader :chat_client

    def initialize(
      api_key:,
      llm_options: {},
      default_options: {},
      embedding_deployment_url: nil,
      chat_deployment_url: nil
    )
      depends_on "ruby-openai", req: "openai"
      @embed_client = ::OpenAI::Client.new(
        access_token: api_key,
        uri_base: embedding_deployment_url,
        **llm_options
      )
      @chat_client = ::OpenAI::Client.new(
        access_token: api_key,
        uri_base: chat_deployment_url,
        **llm_options
      )
      @defaults = DEFAULTS.merge(default_options)
    end

    def embed(...)
      @client = @embed_client
      super(...)
    end

    def complete(...)
      @client = @chat_client
      super(...)
    end

    def chat(...)
      @client = @chat_client
      super(...)
    end
  end
end

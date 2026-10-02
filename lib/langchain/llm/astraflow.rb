# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Astraflow by UCloud — OpenAI-compatible platform supporting 200+ models
  # https://astraflow.ucloud-global.com (global) / https://astraflow.ucloud.cn (China)
  #
  # Gem requirements:
  #    gem "ruby-openai", "~> 8.1.0"
  #
  # Usage (global endpoint):
  #    llm = Langchain::LLM::Astraflow.new(api_key: ENV["ASTRAFLOW_API_KEY"])
  #
  # Usage (China endpoint):
  #    llm = Langchain::LLM::Astraflow.new(api_key: ENV["ASTRAFLOW_CN_API_KEY"], endpoint: :cn)
  #
  # Usage (custom model):
  #    llm = Langchain::LLM::Astraflow.new(
  #      api_key: ENV["ASTRAFLOW_API_KEY"],
  #      default_options: { chat_model: "gpt-4o" }
  #    )
  class Astraflow < OpenAI
    GLOBAL_API_URL = "https://api-us-ca.umodelverse.ai/v1"
    CN_API_URL = "https://api.modelverse.cn/v1"

    DEFAULTS = {
      n: 1,
      chat_model: "gpt-4o-mini",
      embedding_model: "text-embedding-3-small"
    }.freeze

    # Initialize an Astraflow LLM instance
    #
    # @param api_key [String] The Astraflow API key (ASTRAFLOW_API_KEY for global, ASTRAFLOW_CN_API_KEY for China)
    # @param endpoint [Symbol] :global (default) or :cn to select the China endpoint
    # @param llm_options [Hash] Additional options to pass to the OpenAI::Client constructor
    # @param default_options [Hash] Default model options
    def initialize(api_key:, endpoint: :global, llm_options: {}, default_options: {})
      depends_on "ruby-openai", req: "openai"

      uri_base = (endpoint.to_sym == :cn) ? CN_API_URL : GLOBAL_API_URL

      llm_options[:log_errors] = Langchain.logger.debug? unless llm_options.key?(:log_errors)

      @client = ::OpenAI::Client.new(access_token: api_key, uri_base: uri_base, **llm_options) do |f|
        f.response :logger, Langchain.logger, {headers: true, bodies: true, errors: true}
      end

      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        logprobs: {},
        top_logprobs: {},
        n: {default: @defaults[:n]},
        temperature: {default: @defaults[:temperature]},
        user: {},
        response_format: {default: @defaults[:response_format]}
      )
      chat_parameters.ignore(:top_k)
    end
  end
end

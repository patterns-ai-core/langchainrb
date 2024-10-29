# frozen_string_literal: true

module Langchain::LLM
  # Gem requirements:
  #    gem "mistral-ai"
  #
  # Usage:
  #    llm = Langchain::LLM::MistralAI.new(api_key: ENV["MISTRAL_AI_API_KEY"])
  class MistralAI < Base
    DEFAULTS = {
      chat_model: "mistral-large-latest",
      embedding_model: "mistral-embed"
    }.freeze

    attr_reader :defaults

    def initialize(api_key:, default_options: {})
      depends_on "mistral-ai"

      @client = Mistral.new(
        credentials: {api_key: api_key},
        options: {server_sent_events: true}
      )

      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        n: {default: @defaults[:n]},
        safe_prompt: {},
        temperature: {default: @defaults[:temperature]},
        response_format: {default: @defaults[:response_format]}
      )
      chat_parameters.remap(seed: :random_seed)
      chat_parameters.ignore(:n, :top_k)
    end

    def chat(params = {})
      parameters = chat_parameters.to_params(params)

      response = client.chat_completions(parameters)

      Langchain::LLM::MistralAIResponse.new(response.to_h)
    end

    def embed(
      text:,
      model: defaults[:embedding_model],
      encoding_format: nil
    )
      params = {
        input: text,
        model: model
      }
      params[:encoding_format] = encoding_format if encoding_format

      response = client.embeddings(params)

      Langchain::LLM::MistralAIResponse.new(response.to_h)
    end
  end
end

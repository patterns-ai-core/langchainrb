# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around the Cohere API.
  #
  # Gem requirements:
  #     gem "cohere-ruby", "~> 0.9.6"
  #
  # Usage:
  #     llm = Langchain::LLM::Cohere.new(api_key: ENV["COHERE_API_KEY"])
  #
  class Cohere < Base
    DEFAULTS = {
      temperature: 0.0,
      completion_model: "command",
      chat_model: "command-r-plus",
      embedding_model: "small",
      dimensions: 1024,
      truncate: "START"
    }.freeze

    def initialize(api_key:, default_options: {})
      depends_on "cohere-ruby", req: "cohere"

      @client = ::Cohere::Client.new(api_key: api_key)
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        response_format: {default: @defaults[:response_format]}
      )
      chat_parameters.remap(
        system: :preamble,
        messages: :chat_history,
        stop: :stop_sequences,
        top_k: :k,
        top_p: :p
      )
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Langchain::LLM::CohereResponse] Response object
    #
    def embed(text:)
      response = client.embed(
        texts: [text],
        model: @defaults[:embedding_model]
      )

      Langchain::LLM::CohereResponse.new response, model: @defaults[:embedding_model]
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params[:stop_sequences]
    # @return [Langchain::LLM::CohereResponse] Response object
    #
    def complete(prompt:, **params)
      default_params = {
        prompt: prompt,
        temperature: @defaults[:temperature],
        model: @defaults[:completion_model],
        truncate: @defaults[:truncate]
      }

      if params[:stop_sequences]
        default_params[:stop_sequences] = params.delete(:stop_sequences)
      end

      default_params.merge!(params)

      response = client.generate(**default_params)
      Langchain::LLM::CohereResponse.new response, model: @defaults[:completion_model]
    end

    # Generate a chat completion for given messages
    #
    # @param [Hash] params unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<String>] :messages Input messages
    # @option params [String] :model The model that will complete your prompt
    # @option params [Integer] :max_tokens Maximum number of tokens to generate before stopping
    # @option params [Array<String>] :stop Custom text sequences that will cause the model to stop generating
    # @option params [Boolean] :stream Whether to incrementally stream the response using server-sent events
    # @option params [String] :system System prompt
    # @option params [Float] :temperature Amount of randomness injected into the response
    # @option params [Array<String>] :tools Definitions of tools that the model may use
    # @option params [Integer] :top_k Only sample from the top K options for each subsequent token
    # @option params [Float] :top_p Use nucleus sampling.
    # @return [Langchain::LLM::CohereResponse] The chat completion
    def chat(params = {})
      raise ArgumentError.new("messages argument is required") if Array(params[:messages]).empty?

      parameters = chat_parameters.to_params(params)

      # Cohere API requires `message:` parameter to be sent separately from `chat_history:`.
      # We extract the last message from the messages param.
      parameters[:message] = parameters[:chat_history].pop&.dig(:message)

      response = client.chat(**parameters)

      Langchain::LLM::CohereResponse.new(response)
    end

    # Generate a summary in English for a given text
    #
    # More parameters available to extend this method with: https://github.com/andreibondarev/cohere-ruby/blob/0.9.4/lib/cohere/client.rb#L107-L115
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    def summarize(text:)
      response = client.summarize(text: text)
      response.dig("summary")
    end
  end
end

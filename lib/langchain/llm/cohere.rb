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
      chat_model: "command-r-plus",
      embedding_model: "embed-english-v3.0",
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
        stop: :stop_sequences,
        top_k: :k,
        top_p: :p
      )
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param input_type [String] "search_document", "search_query", "classification" or "clustering"
    # @return [Langchain::LLM::Response::CohereResponse] Response object
    #
    def embed(text:, input_type: "search_document")
      response = client.embed(
        texts: [text],
        model: @defaults[:embedding_model],
        input_type: input_type,
        embedding_types: ["float"]
      )

      Langchain::LLM::Response::CohereResponse.new response, model: @defaults[:embedding_model]
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
    # @return [Langchain::LLM::Response::CohereResponse] The chat completion
    def chat(params = {})
      raise ArgumentError.new("messages argument is required") if Array(params[:messages]).empty?

      parameters = chat_parameters.to_params(params)

      # The v2 Chat API takes the system prompt as the first message.
      messages = Array(parameters[:messages]).map { |message| v2_message(message) }
      system = parameters.delete(:system)
      messages.unshift({role: "system", content: system}) if system
      parameters[:messages] = messages

      response = client.chat(**parameters)

      Langchain::LLM::Response::CohereResponse.new(response)
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

    private

    V1_ROLES = {"USER" => "user", "CHATBOT" => "assistant", "SYSTEM" => "system"}.freeze

    # Converts a v1 chat_history entry ({role: "USER", message: "..."}) to a v2 message
    # ({role: "user", content: "..."}); v2 messages are returned unchanged.
    def v2_message(message)
      message = message.transform_keys(&:to_sym)
      return message unless message.key?(:message)

      role = message[:role].to_s
      {role: V1_ROLES.fetch(role.upcase, role.downcase), content: message[:message]}
    end
  end
end

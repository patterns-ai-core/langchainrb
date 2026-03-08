# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around Anthropic APIs.
  #
  # Gem requirements:
  #   gem "anthropic", "~> 1.10"
  #
  # Usage:
  #     llm = Langchain::LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
  #
  class Anthropic < Base
    DEFAULTS = {
      temperature: 0.0,
      chat_model: "claude-sonnet-4-6",
      max_tokens: 256
    }.freeze

    CAPABILITIES = [:chat, :streaming, :tools, :thinking].freeze

    # Initialize an Anthropic LLM instance
    #
    # @param api_key [String] The API key to use
    # @param llm_options [Hash] Options to pass to the Anthropic client
    # @param default_options [Hash] Default options to use on every call to LLM, e.g.: { temperature:, chat_model:, max_tokens:, thinking: }
    # @return [Langchain::LLM::Anthropic] Langchain::LLM::Anthropic instance
    def initialize(api_key:, llm_options: {}, default_options: {})
      depends_on "anthropic"

      @client = ::Anthropic::Client.new(api_key: api_key, **llm_options)
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        max_tokens: {default: @defaults[:max_tokens]},
        metadata: {},
        system: {},
        thinking: {default: @defaults[:thinking]},
        request_options: {}
      )
      chat_parameters.ignore(:n, :user)
      chat_parameters.remap(stop: :stop_sequences)
    end

    # Generate a chat completion for given messages
    #
    # @param [Hash] params unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<String>] :messages Input messages
    # @option params [String] :model The model that will complete your prompt
    # @option params [Integer] :max_tokens Maximum number of tokens to generate before stopping
    # @option params [Hash] :metadata Object describing metadata about the request
    # @option params [Array<String>] :stop_sequences Custom text sequences that will cause the model to stop generating
    # @option params [String] :system System prompt
    # @option params [Float] :temperature Amount of randomness injected into the response
    # @option params [Array<String>] :tools Definitions of tools that the model may use
    # @option params [Hash] :thinking Enable extended thinking mode, e.g. { type: "enabled", budget_tokens: 4000 }
    # @option params [Integer] :top_k Only sample from the top K options for each subsequent token
    # @option params [Float] :top_p Use nucleus sampling.
    # @return [Langchain::LLM::Response::AnthropicResponse] The chat completion
    def chat(params = {}, &block)
      parameters = chat_parameters.to_params(params)

      raise ArgumentError.new("messages argument is required") if Array(parameters[:messages]).empty?
      raise ArgumentError.new("model argument is required") if parameters[:model].empty?
      raise ArgumentError.new("max_tokens argument is required") if parameters[:max_tokens].nil?

      response = if block
        stream_chat(parameters, &block)
      else
        client.messages.create(parameters)
      end

      Langchain::LLM::Response::AnthropicResponse.new(response)
    end

    private

    # Streams a chat completion, yielding events to the caller's block,
    # and returns the accumulated message as a response hash.
    #
    # @param parameters [Hash] The chat parameters
    # @yield [event] Each streaming event
    # @return [Anthropic::Models::Message] The accumulated message
    def stream_chat(parameters)
      stream = client.messages.stream(parameters)
      stream.each { |event| yield event }
      stream.accumulated_message
    end
  end
end

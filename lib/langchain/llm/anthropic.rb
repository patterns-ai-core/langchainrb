# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around Anthropic APIs.
  #
  # Gem requirements:
  #   gem "anthropic", "~> 0.1.0"
  #
  # Usage:
  #     anthorpic = Langchain::LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
  #
  class Anthropic < Base
    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "claude-2.1",
      chat_completion_model_name: "claude-3-sonnet-20240229",
      max_tokens_to_sample: 256
    }.freeze

    # TODO: Implement token length validator for Anthropic
    # LENGTH_VALIDATOR = Langchain::Utils::TokenLength::AnthropicValidator

    # Initialize an Anthropic LLM instance
    #
    # @param api_key [String] The API key to use
    # @param llm_options [Hash] Options to pass to the Anthropic client
    # @param default_options [Hash] Default options to use on every call to LLM, e.g.: { temperature:, completion_model_name:, chat_completion_model_name:, max_tokens_to_sample: }
    # @return [Langchain::LLM::Anthropic] Langchain::LLM::Anthropic instance
    def initialize(api_key:, llm_options: {}, default_options: {})
      depends_on "anthropic"

      @client = ::Anthropic::Client.new(access_token: api_key, **llm_options)
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_completion_model_name]},
        temperature: {default: @defaults[:temperature]},
        max_tokens: {default: @defaults[:max_tokens_to_sample]},
        metadata: {},
        system: {}
      )
      chat_parameters.ignore(:n, :user)
      chat_parameters.remap(stop: :stop_sequences)
    end

    # Generate a completion for a given prompt
    #
    # @param prompt [String] Prompt to generate a completion for
    # @param model [String] The model to use
    # @param max_tokens_to_sample [Integer] The maximum number of tokens to sample
    # @param stop_sequences [Array<String>] The stop sequences to use
    # @param temperature [Float] The temperature to use
    # @param top_p [Float] The top p value to use
    # @param top_k [Integer] The top k value to use
    # @param metadata [Hash] The metadata to use
    # @param stream [Boolean] Whether to stream the response
    # @return [Langchain::LLM::AnthropicResponse] The completion
    def complete(
      prompt:,
      model: @defaults[:completion_model_name],
      max_tokens_to_sample: @defaults[:max_tokens_to_sample],
      stop_sequences: nil,
      temperature: @defaults[:temperature],
      top_p: nil,
      top_k: nil,
      metadata: nil,
      stream: nil
    )
      raise ArgumentError.new("model argument is required") if model.empty?
      raise ArgumentError.new("max_tokens_to_sample argument is required") if max_tokens_to_sample.nil?

      parameters = {
        model: model,
        prompt: prompt,
        max_tokens_to_sample: max_tokens_to_sample,
        temperature: temperature
      }
      parameters[:stop_sequences] = stop_sequences if stop_sequences
      parameters[:top_p] = top_p if top_p
      parameters[:top_k] = top_k if top_k
      parameters[:metadata] = metadata if metadata
      parameters[:stream] = stream if stream

      response = client.complete(parameters: parameters)
      Langchain::LLM::AnthropicResponse.new(response)
    end

    # Generate a chat completion for given messages
    #
    # @param [Hash] params unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<String>] :messages Input messages
    # @option params [String] :model The model that will complete your prompt
    # @option params [Integer] :max_tokens Maximum number of tokens to generate before stopping
    # @option params [Hash] :metadata Object describing metadata about the request
    # @option params [Array<String>] :stop_sequences Custom text sequences that will cause the model to stop generating
    # @option params [Boolean] :stream Whether to incrementally stream the response using server-sent events
    # @option params [String] :system System prompt
    # @option params [Float] :temperature Amount of randomness injected into the response
    # @option params [Array<String>] :tools Definitions of tools that the model may use
    # @option params [Integer] :top_k Only sample from the top K options for each subsequent token
    # @option params [Float] :top_p Use nucleus sampling.
    # @return [Langchain::LLM::AnthropicResponse] The chat completion
    def chat(params = {})
      parameters = chat_parameters.to_params(params)

      raise ArgumentError.new("messages argument is required") if Array(parameters[:messages]).empty?
      raise ArgumentError.new("model argument is required") if parameters[:model].empty?
      raise ArgumentError.new("max_tokens argument is required") if parameters[:max_tokens].nil?

      response = client.messages(parameters: parameters)

      Langchain::LLM::AnthropicResponse.new(response)
    end
  end
end

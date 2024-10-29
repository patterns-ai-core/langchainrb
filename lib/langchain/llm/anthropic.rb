# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around Anthropic APIs.
  #
  # Gem requirements:
  #   gem "anthropic", "~> 0.3.2"
  #
  # Usage:
  #     llm = Langchain::LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
  #
  class Anthropic < Base
    DEFAULTS = {
      temperature: 0.0,
      completion_model: "claude-2.1",
      chat_model: "claude-3-5-sonnet-20240620",
      max_tokens: 256
    }.freeze

    # Initialize an Anthropic LLM instance
    #
    # @param api_key [String] The API key to use
    # @param llm_options [Hash] Options to pass to the Anthropic client
    # @param default_options [Hash] Default options to use on every call to LLM, e.g.: { temperature:, completion_model:, chat_model:, max_tokens: }
    # @return [Langchain::LLM::Anthropic] Langchain::LLM::Anthropic instance
    def initialize(api_key:, llm_options: {}, default_options: {})
      depends_on "anthropic"

      @client = ::Anthropic::Client.new(access_token: api_key, **llm_options)
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        max_tokens: {default: @defaults[:max_tokens]},
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
      model: @defaults[:completion_model],
      max_tokens: @defaults[:max_tokens],
      stop_sequences: nil,
      temperature: @defaults[:temperature],
      top_p: nil,
      top_k: nil,
      metadata: nil,
      stream: nil
    )
      raise ArgumentError.new("model argument is required") if model.empty?
      raise ArgumentError.new("max_tokens argument is required") if max_tokens.nil?

      parameters = {
        model: model,
        prompt: prompt,
        max_tokens_to_sample: max_tokens,
        temperature: temperature
      }
      parameters[:stop_sequences] = stop_sequences if stop_sequences
      parameters[:top_p] = top_p if top_p
      parameters[:top_k] = top_k if top_k
      parameters[:metadata] = metadata if metadata
      parameters[:stream] = stream if stream

      response = with_api_error_handling do
        client.complete(parameters: parameters)
      end

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
    def chat(params = {}, &block)
      set_extra_headers! if params[:tools]

      parameters = chat_parameters.to_params(params)

      raise ArgumentError.new("messages argument is required") if Array(parameters[:messages]).empty?
      raise ArgumentError.new("model argument is required") if parameters[:model].empty?
      raise ArgumentError.new("max_tokens argument is required") if parameters[:max_tokens].nil?

      if block
        @response_chunks = []
        parameters[:stream] = proc do |chunk|
          @response_chunks << chunk
          yield chunk
        end
      end

      response = client.messages(parameters: parameters)

      response = response_from_chunks if block
      reset_response_chunks

      Langchain::LLM::AnthropicResponse.new(response)
    end

    def with_api_error_handling
      response = yield
      return if response.empty?

      raise Langchain::LLM::ApiError.new "Anthropic API error: #{response.dig("error", "message")}" if response&.dig("error")

      response
    end

    def response_from_chunks
      grouped_chunks = @response_chunks.group_by { |chunk| chunk["index"] }.except(nil)

      usage = @response_chunks.find { |chunk| chunk["type"] == "message_delta" }&.dig("usage")
      stop_reason = @response_chunks.find { |chunk| chunk["type"] == "message_delta" }&.dig("delta", "stop_reason")

      content = grouped_chunks.map do |_index, chunks|
        text = chunks.map { |chunk| chunk.dig("delta", "text") }.join
        if !text.nil? && !text.empty?
          {"type" => "text", "text" => text}
        else
          tool_calls_from_choice_chunks(chunks)
        end
      end.flatten

      @response_chunks.first&.slice("id", "object", "created", "model")
        &.merge!(
          {
            "content" => content,
            "usage" => usage,
            "role" => "assistant",
            "stop_reason" => stop_reason
          }
        )
    end

    def tool_calls_from_choice_chunks(chunks)
      return unless (first_block = chunks.find { |chunk| chunk.dig("content_block", "type") == "tool_use" })

      chunks.group_by { |chunk| chunk["index"] }.map do |index, chunks|
        input = chunks.select { |chunk| chunk.dig("delta", "partial_json") }
          .map! { |chunk| chunk.dig("delta", "partial_json") }.join
        {
          "id" => first_block.dig("content_block", "id"),
          "type" => "tool_use",
          "name" => first_block.dig("content_block", "name"),
          "input" => JSON.parse(input).transform_keys(&:to_sym)
        }
      end.compact
    end

    private

    def reset_response_chunks
      @response_chunks = []
    end

    def set_extra_headers!
      ::Anthropic.configuration.extra_headers = {"anthropic-beta": "tools-2024-05-16"}
    end
  end
end

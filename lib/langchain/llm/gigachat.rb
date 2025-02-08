# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Gigachat APIs: https://developers.sber.ru/docs/ru/gigachat/api/overview
  #
  # Gem requirements:
  #    gem "gigachat", "~> 0.1.0"
  #
  # Usage:
  #    llm = Langchain::LLM::Gigachat.new(
  #      api_type: "GIGACHAT_API_CORP", # or GIGACHAT_API_PERS, GIGACHAT_API_B2B
  #      api_key: "Yjgy...VhYw==" # your authorization data
  #    )
  class Gigachat < Base
    DEFAULTS = {
      temperature: 0.0,
      chat_model: "GigaChat",
      embedding_model: "GigaChat"
    }.freeze

    EMBEDDING_SIZES = {}.freeze

    # Initialize an GigaChat LLM instance
    #
    # @param api_key [String] The API key to use
    # @param llm_options [Hash] Options to pass to the GigaChat::Client constructor
    def initialize(api_key:, llm_options: {}, default_options: {})
      depends_on "gigachat"

      llm_options[:log_errors] = Langchain.logger.debug? unless llm_options.key?(:log_errors)
      llm_options[:extra_headers] = {"X-Session-ID" => SecureRandom.uuid} if llm_options.dig(:extra_headers, "X-Session-ID").nil?
      @client = GigaChat::Client.new(client_base64: api_key, **llm_options) do |f|
        f.response :logger, Langchain.logger, {headers: true, bodies: true, errors: true}
      end
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        # logprobs: {},
        # top_logprobs: {},
        temperature: {default: @defaults[:temperature]},
        # user: {},
        response_format: {default: @defaults[:response_format]}
      )
      chat_parameters.ignore(:top_k)
    end

    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param model [String] ID of the model to use
    # @param encoding_format [String] The format to return the embeddings in. Can be either float or base64.
    # @param user [String] A unique identifier representing your end-user
    # @return [Langchain::LLM::GigachatResponse] Response object
    def embed(
      text:,
      model: defaults[:embedding_model],
      encoding_format: nil,
      user: nil
      # dimensions: @defaults[:dimensions]
    )
      raise ArgumentError.new("text argument is required") if text.empty?
      raise ArgumentError.new("model argument is required") if model.empty?
      raise ArgumentError.new("encoding_format must be either float or base64") if encoding_format && %w[float base64].include?(encoding_format)

      parameters = {
        input: text,
        model: model
      }
      parameters[:encoding_format] = encoding_format if encoding_format
      parameters[:user] = user if user

      # if dimensions
      #   parameters[:dimensions] = dimensions
      # elsif EMBEDDING_SIZES.key?(model)
      #   parameters[:dimensions] = EMBEDDING_SIZES[model]
      # end

      # dimensions parameter not supported by gigachat
      parameters.delete(:dimensions)

      response = with_api_error_handling do
        client.embeddings(parameters: parameters)
      end

      Langchain::LLM::GigachatResponse.new(response)
    end

    # rubocop:disable Style/ArgumentsForwarding
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params [Hash] The parameters to pass to the `chat()` method
    # @return [Langchain::LLM::GigachatResponse] Response object
    def complete(prompt:, **params)
      Langchain.logger.warn "DEPRECATED: `Langchain::LLM::Gigachat#complete` is deprecated, and will be removed in the next major version. Use `Langchain::LLM::Gigachat#chat` instead."

      if params[:stop_sequences]
        params[:stop] = params.delete(:stop_sequences)
      end
      # Should we still accept the `messages: []` parameter here?
      messages = [{role: "user", content: prompt}]
      chat(messages: messages, **params)
    end

    # rubocop:enable Style/ArgumentsForwarding

    # Generate a chat completion for given messages.
    #
    # @param [Hash] params unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<Hash>] :messages List of messages comprising the conversation so far
    # @option params [String] :model ID of the model to use
    def chat(params = {}, &block)
      parameters = chat_parameters
      parameters.remap(tools: :functions, tool_choice: :function_call)
      parameters = parameters.to_params(params)
      raise ArgumentError.new("messages argument is required") if Array(parameters[:messages]).empty?
      raise ArgumentError.new("model argument is required") if parameters[:model].to_s.empty?
      if parameters[:function_call] && Array(parameters[:functions]).empty?
        raise ArgumentError.new("'tool_choice' is only allowed when 'tools' are specified.")
      end

      if block
        @response_chunks = []
        parameters[:stream_options] = {include_usage: true}
        parameters[:stream] = proc do |chunk, _bytesize|
          chunk_content = chunk.dig("choices", 0) || {}
          @response_chunks << chunk
          yield chunk_content
        end
      end
      response = with_api_error_handling do
        client.chat(parameters: parameters)
      end
      response = response_from_chunks if block
      reset_response_chunks

      Langchain::LLM::GigachatResponse.new(response)
    end

    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(prompt: prompt)
    end

    def default_dimensions
      @defaults[:dimensions] || EMBEDDING_SIZES.fetch(defaults[:embedding_model])
    end

    private

    attr_reader :response_chunks

    def reset_response_chunks
      @response_chunks = []
    end

    def with_api_error_handling
      response = yield
      return if response.empty?

      raise Langchain::LLM::ApiError.new "GigaChat API error: #{response.dig("status")}, #{response.dig("message")}" if response&.dig("status")

      response
    end

    def response_from_chunks
      grouped_chunks = @response_chunks
        .group_by { |chunk| chunk.dig("choices", 0, "index") }
        .except(nil) # the last chunk (that contains the token usage) has no index
      final_choices = grouped_chunks.map do |index, chunks|
        {
          "index" => index,
          "message" => {
            "role" => "assistant",
            "content" => chunks.map { |chunk| chunk.dig("choices", 0, "delta", "content") }.join,
            "tool_calls" => tool_calls_from_choice_chunks(chunks)
          }.compact,
          "finish_reason" => chunks.last.dig("choices", 0, "finish_reason")
        }
      end
      @response_chunks.first&.slice("id", "object", "created", "model")&.merge({"choices" => final_choices, "usage" => @response_chunks.last["usage"]})
    end

    def tool_calls_from_choice_chunks(choice_chunks)
      chunks_by_index = choice_chunks.group_by { |chunk| chunk.dig("choices", 0, "index") }
      res = chunks_by_index.map do |_index, chunks|
        deltas = chunks.map { |chunk| chunk.dig("choices", 0, "delta") }
        next unless deltas.any? { |delta| delta["function_call"] }

        func = deltas.find { |delta| delta["function_call"] }
        {
          "id" => deltas.find { |delta| delta["functions_state_id"]}&.dig("functions_state_id"),
          "type" => func.dig("function_call", "type"),
          "function" => {
            "name" => func.dig("function_call", "name"),
            "arguments" => chunks.map { |chunk| chunk.dig("choices", 0, "delta", "function_call", "arguments") }.join
          }
        }
      end.compact
      res.empty? ? nil : res
    end
  end
end

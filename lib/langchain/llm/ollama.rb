# frozen_string_literal: true

module Langchain::LLM
  # Interface to Ollama API.
  # Available models: https://ollama.ai/library
  #
  # Gem requirements:
  #    gem "faraday"
  #
  # Usage:
  #    llm = Langchain::LLM::Ollama.new(url: ENV["OLLAMA_URL"], default_options: {})
  #
  class Ollama < Base
    attr_reader :url, :defaults

    DEFAULTS = {
      temperature: 0.0,
      completion_model: "llama3.2",
      embedding_model: "llama3.2",
      chat_model: "llama3.2",
      options: {}
    }.freeze

    EMBEDDING_SIZES = {
      codellama: 4_096,
      "dolphin-mixtral": 4_096,
      llama2: 4_096,
      llama3: 4_096,
      "llama3.1": 4_096,
      "llama3.2": 3_072,
      llava: 4_096,
      mistral: 4_096,
      "mistral-openorca": 4_096,
      mixtral: 4_096,
      tinydolphin: 2_048
    }.freeze

    # Initialize the Ollama client
    # @param url [String] The URL of the Ollama instance
    # @param api_key [String] The API key to use. This is optional and used when you expose Ollama API using Open WebUI
    # @param default_options [Hash] The default options to use
    #
    def initialize(url: "http://localhost:11434", api_key: nil, default_options: {})
      depends_on "faraday"
      @url = url
      @api_key = api_key
      @defaults = DEFAULTS.merge(default_options)
      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        template: {},
        stream: {default: false},
        response_format: {default: @defaults[:response_format]},
        options: {default: @defaults[:options]}
      )
      chat_parameters.remap(response_format: :format)
    end

    # Returns the # of vector dimensions for the embeddings
    # @return [Integer] The # of vector dimensions
    def default_dimensions
      # since Ollama can run multiple models, look it up or generate an embedding and return the size
      @default_dimensions ||=
        EMBEDDING_SIZES.fetch(defaults[:embedding_model].to_sym) do
          embed(text: "test").embedding.size
        end
    end

    #
    # Generate the completion for a given prompt
    #
    # @param prompt [String] The prompt to complete
    # @param model [String] The model to use
    #   For a list of valid parameters and values, see:
    #   https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
    # @option block [Proc] Receive the intermediate responses as a stream of +OllamaResponse+ objects.
    # @return [Langchain::LLM::Response::OllamaResponse] Response object
    #
    # Example:
    #
    #  final_resp = ollama.complete(prompt:) { |resp| print resp.completion }
    #  final_resp.total_tokens
    #
    def complete(
      prompt:,
      model: defaults[:completion_model],
      images: nil,
      format: nil,
      system: nil,
      template: nil,
      context: nil,
      raw: nil,
      mirostat: nil,
      mirostat_eta: nil,
      mirostat_tau: nil,
      num_ctx: nil,
      num_gqa: nil,
      num_gpu: nil,
      num_thread: nil,
      repeat_last_n: nil,
      repeat_penalty: nil,
      temperature: defaults[:temperature],
      seed: nil,
      stop: nil,
      tfs_z: nil,
      num_predict: nil,
      top_k: nil,
      top_p: nil,
      stop_sequences: nil,
      &block
    )
      if stop_sequences
        stop = stop_sequences
      end

      parameters = {
        prompt: prompt,
        model: model,
        images: images,
        format: format,
        system: system,
        template: template,
        context: context,
        stream: block_given?, # rubocop:disable Performance/BlockGivenWithExplicitBlock
        raw: raw
      }.compact

      llm_parameters = {
        mirostat: mirostat,
        mirostat_eta: mirostat_eta,
        mirostat_tau: mirostat_tau,
        num_ctx: num_ctx,
        num_gqa: num_gqa,
        num_gpu: num_gpu,
        num_thread: num_thread,
        repeat_last_n: repeat_last_n,
        repeat_penalty: repeat_penalty,
        temperature: temperature,
        seed: seed,
        stop: stop,
        tfs_z: tfs_z,
        num_predict: num_predict,
        top_k: top_k,
        top_p: top_p
      }

      parameters[:options] = llm_parameters.compact
      responses_stream = []

      client.post("api/generate", parameters) do |req|
        req.options.on_data = json_responses_chunk_handler do |parsed_chunk|
          responses_stream << parsed_chunk

          block&.call(Langchain::LLM::Response::OllamaResponse.new(parsed_chunk, model: parameters[:model]))
        end
      end

      generate_final_completion_response(responses_stream, parameters[:model])
    end

    # Generate a chat completion
    #
    # @param messages [Array] The chat messages
    # @param model [String] The model to use
    # @param params [Hash] Unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<Hash>] :messages Array of messages
    # @option params [String] :model Model name
    # @option params [String] :format Format to return a response in. Currently the only accepted value is `json`
    # @option params [Float] :temperature The temperature to use
    # @option params [String] :template The prompt template to use (overrides what is defined in the `Modelfile`)
    # @option block [Proc] Receive the intermediate responses as a stream of +OllamaResponse+ objects.
    # @return [Langchain::LLM::Response::OllamaResponse] Response object
    #
    # Example:
    #
    #  final_resp = ollama.chat(messages:) { |resp| print resp.chat_completion }
    #  final_resp.total_tokens
    #
    # The message object has the following fields:
    #   role: the role of the message, either system, user or assistant
    #   content: the content of the message
    #   images (optional): a list of images to include in the message (for multimodal models such as llava)
    def chat(messages:, model: nil, **params, &block)
      parameters = chat_parameters.to_params(params.merge(messages:, model:, stream: block_given?)) # rubocop:disable Performance/BlockGivenWithExplicitBlock
      responses_stream = []

      client.post("api/chat", parameters) do |req|
        req.options.on_data = json_responses_chunk_handler do |parsed_chunk|
          responses_stream << parsed_chunk

          block&.call(Langchain::LLM::Response::OllamaResponse.new(parsed_chunk, model: parameters[:model]))
        end
      end

      generate_final_chat_completion_response(responses_stream, parameters[:model])
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param model [String] The model to use
    # @param options [Hash] The options to use
    # @return [Langchain::LLM::Response::OllamaResponse] Response object
    #
    def embed(
      text:,
      model: defaults[:embedding_model],
      mirostat: nil,
      mirostat_eta: nil,
      mirostat_tau: nil,
      num_ctx: nil,
      num_gqa: nil,
      num_gpu: nil,
      num_thread: nil,
      repeat_last_n: nil,
      repeat_penalty: nil,
      temperature: defaults[:temperature],
      seed: nil,
      stop: nil,
      tfs_z: nil,
      num_predict: nil,
      top_k: nil,
      top_p: nil
    )
      parameters = {
        model: model,
        input: Array(text)
      }.compact

      llm_parameters = {
        mirostat: mirostat,
        mirostat_eta: mirostat_eta,
        mirostat_tau: mirostat_tau,
        num_ctx: num_ctx,
        num_gqa: num_gqa,
        num_gpu: num_gpu,
        num_thread: num_thread,
        repeat_last_n: repeat_last_n,
        repeat_penalty: repeat_penalty,
        temperature: temperature,
        seed: seed,
        stop: stop,
        tfs_z: tfs_z,
        num_predict: num_predict,
        top_k: top_k,
        top_p: top_p
      }

      parameters[:options] = llm_parameters.compact

      response = client.post("api/embed") do |req|
        req.body = parameters
      end

      Langchain::LLM::Response::OllamaResponse.new(response.body, model: parameters[:model])
    end

    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/ollama/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(prompt: prompt)
    end

    private

    def client
      @client ||= Faraday.new(url: url, headers: auth_headers) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
        conn.response :logger, Langchain.logger, {headers: true, bodies: true, errors: true}
      end
    end

    def auth_headers
      return unless @api_key

      {"Authorization" => "Bearer #{@api_key}"}
    end

    def json_responses_chunk_handler(&block)
      incomplete_chunk_line = nil
      proc do |chunk, _size|
        chunk.split("\n").each do |chunk_line|
          if incomplete_chunk_line
            chunk_line = incomplete_chunk_line + chunk_line
            incomplete_chunk_line = nil
          end

          parsed_chunk = begin
            JSON.parse(chunk_line)

            # In some instance the chunk exceeds the buffer size and the JSON parser fails
          rescue JSON::ParserError
            if chunk_line.end_with?("}")
              raise
            else
              incomplete_chunk_line = chunk_line
              nil
            end
          end

          block.call(parsed_chunk) unless parsed_chunk.nil?
        end
      end
    end

    def generate_final_completion_response(responses_stream, model)
      final_response = responses_stream.last.merge(
        "response" => responses_stream.map { |resp| resp["response"] }.join
      )

      Langchain::LLM::Response::OllamaResponse.new(final_response, model: model)
    end

    # BUG: If streamed, this method does not currently return the tool_calls response.
    def generate_final_chat_completion_response(responses_stream, model)
      final_response = responses_stream.last
      final_response["message"]["content"] = responses_stream.map { |resp| resp.dig("message", "content") }.join

      Langchain::LLM::Response::OllamaResponse.new(final_response, model: model)
    end
  end
end

# frozen_string_literal: true

module Langchain::LLM
  # Interface to Ollama API.
  # Available models: https://ollama.ai/library
  #
  # Usage:
  #    ollama = Langchain::LLM::Ollama.new(url: ENV["OLLAMA_URL"], default_options: {})
  #
  class Ollama < Base
    attr_reader :url, :defaults

    DEFAULTS = {
      temperature: 0.8,
      completion_model_name: "llama2",
      embeddings_model_name: "llama2",
      chat_completion_model_name: "llama2"
    }.freeze

    # Initialize the Ollama client
    # @param url [String] The URL of the Ollama instance
    # @param default_options [Hash] The default options to use
    #
    def initialize(url:, default_options: {})
      @url = url
      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate the completion for a given prompt
    #
    # @param prompt [String] The prompt to complete
    # @param model [String] The model to use
    #   For a list of valid parameters and values, see:
    #   https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
    # @return [Langchain::LLM::OllamaResponse] Response object
    #
    def complete(
      prompt:,
      model: defaults[:completion_model_name],
      images: nil,
      format: nil,
      system: nil,
      template: nil,
      context: nil,
      stream: nil,
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
        stream: stream,
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

      response = ""

      client.post("api/generate") do |req|
        req.body = parameters

        req.options.on_data = proc do |chunk, size|
          json_chunk = JSON.parse(chunk)

          response += json_chunk.dig("response")

          yield json_chunk, size if block
        end
      end

      Langchain::LLM::OllamaResponse.new(response, model: parameters[:model])
    end

    # Generate a chat completion
    #
    # @param model [String] Model name
    # @param messages [Array<Hash>] Array of messages
    # @param format [String] Format to return a response in. Currently the only accepted value is `json`
    # @param temperature [Float] The temperature to use
    # @param template [String] The prompt template to use (overrides what is defined in the `Modelfile`)
    # @param stream [Boolean] Streaming the response. If false the response will be returned as a single response object, rather than a stream of objects
    #
    # The message object has the following fields:
    #   role: the role of the message, either system, user or assistant
    #   content: the content of the message
    #   images (optional): a list of images to include in the message (for multimodal models such as llava)
    def chat(
      model: defaults[:chat_completion_model_name],
      messages: [],
      format: nil,
      temperature: defaults[:temperature],
      template: nil,
      stream: false # TODO: Fix streaming.
    )
      parameters = {
        model: model,
        messages: messages,
        format: format,
        temperature: temperature,
        template: template,
        stream: stream
      }.compact

      response = client.post("api/chat") do |req|
        req.body = parameters
      end

      Langchain::LLM::OllamaResponse.new(response.body, model: parameters[:model])
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param model [String] The model to use
    # @param options [Hash] The options to use
    # @return [Langchain::LLM::OllamaResponse] Response object
    #
    def embed(
      text:,
      model: defaults[:embeddings_model_name],
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
        prompt: text,
        model: model
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

      response = client.post("api/embeddings") do |req|
        req.body = parameters
      end

      Langchain::LLM::OllamaResponse.new(response.body, model: parameters[:model])
    end

    private

    # @return [Faraday::Connection] Faraday client
    def client
      @client ||= Faraday.new(url: url) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end
  end
end

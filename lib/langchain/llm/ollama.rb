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
      format:nil,
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
      &block)

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
      temperature: nil,
      seed: nil,
      stop: nil,
      tfs_z: nil,
      num_predict: nil,
      top_k: nil,
      top_p: nil
    )
      parameters = {
        prompt: text,
        model: model,
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

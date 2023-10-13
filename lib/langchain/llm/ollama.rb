# frozen_string_literal: true

module Langchain::LLM
  # Interface to Ollama API.
  # Available models: https://ollama.ai/library
  #
  # Usage:
  #    ollama = Langchain::LLM::Ollama.new(url: ENV["OLLAMA_URL"])
  #
  class Ollama < Base
    attr_reader :url

    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "llama2",
      embeddings_model_name: "llama2"
    }.freeze

    # Initialize the Ollama client
    # @param url [String] The URL of the Ollama instance
    def initialize(url:)
      @url = url
    end

    #
    # Generate the completion for a given prompt
    #
    # @param prompt [String] The prompt to complete
    # @param model [String] The model to use
    # @param options [Hash] The options to use (https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)
    # @return [Langchain::LLM::OllamaResponse] Response object
    #
    def complete(prompt:, model: nil, **options)
      response = +""

      model_name = model || DEFAULTS[:completion_model_name]

      client.post("api/generate") do |req|
        req.body = {}
        req.body["prompt"] = prompt
        req.body["model"] = model_name

        req.body["options"] = options if options.any?

        # TODO: Implement streaming support when a &block is passed in
        req.options.on_data = proc do |chunk, size|
          json_chunk = JSON.parse(chunk)

          unless json_chunk.dig("done")
            response.to_s << JSON.parse(chunk).dig("response")
          end
        end
      end

      Langchain::LLM::OllamaResponse.new(response, model: model_name)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param model [String] The model to use
    # @param options [Hash] The options to use
    # @return [Langchain::LLM::OllamaResponse] Response object
    #
    def embed(text:, model: nil, **options)
      model_name = model || DEFAULTS[:embeddings_model_name]

      response = client.post("api/embeddings") do |req|
        req.body = {}
        req.body["prompt"] = text
        req.body["model"] = model_name

        req.body["options"] = options if options.any?
      end

      Langchain::LLM::OllamaResponse.new(response.body, model: model_name)
    end

    private

    def client
      @client ||= Faraday.new(url: url) do |conn|
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end
  end
end

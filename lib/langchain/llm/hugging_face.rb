# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around the HuggingFace Inference API: https://huggingface.co/inference-api
  #
  # Gem requirements:
  #     gem "hugging-face", "~> 0.3.4"
  #
  # Usage:
  #     llm = Langchain::LLM::HuggingFace.new(api_key: ENV["HUGGING_FACE_API_KEY"])
  #
  class HuggingFace < Base
    DEFAULTS = {
      embedding_model: "sentence-transformers/all-MiniLM-L6-v2"
    }.freeze

    EMBEDDING_SIZES = {
      "sentence-transformers/all-MiniLM-L6-v2": 384
    }.freeze

    #
    # Intialize the HuggingFace LLM
    #
    # @param api_key [String] The API key to use
    #
    def initialize(api_key:, default_options: {})
      depends_on "hugging-face", req: "hugging_face"

      @client = ::HuggingFace::InferenceApi.new(api_token: api_key)
      @defaults = DEFAULTS.merge(default_options)
    end

    # Returns the # of vector dimensions for the embeddings
    # @return [Integer] The # of vector dimensions
    def default_dimensions
      # since Huggin Face can run multiple models, look it up or generate an embedding and return the size
      @default_dimensions ||= @defaults[:dimensions] ||
        EMBEDDING_SIZES.fetch(@defaults[:embedding_model].to_sym) do
          embed(text: "test").embedding.size
        end
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to embed
    # @return [Langchain::LLM::HuggingFaceResponse] Response object
    #
    def embed(text:)
      response = client.embedding(
        input: text,
        model: @defaults[:embedding_model]
      )
      Langchain::LLM::HuggingFaceResponse.new(response, model: @defaults[:embedding_model])
    end
  end
end

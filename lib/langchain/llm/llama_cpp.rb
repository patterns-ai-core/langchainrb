# frozen_string_literal: true

module Langchain::LLM
  class LlamaCpp < Base
    attr_reader :model_path

    def initialize(model_path:)
      depends_on "llama_cpp"
      require "llama_cpp"

      @model_path = model_path
    end

    def complete(prompt:, **params)
      params = ::LLaMACpp::ContextParams.new
      params.seed = 12
      params.n_gpu_layers = n_gpu_layers

      model = ::LLaMACpp::Model.new(model_path: model_path, params: params)
      context = ::LLaMACpp::Context.new(model: model)

      ::LLaMACpp.generate(context, prompt, n_threads: n_threads)
    end

    def embed(text:)
      params = ::LLaMACpp::ContextParams.new
      params.seed = 12
      params.n_gpu_layers = n_gpu_layers
      params.embedding = true

      model = ::LLaMACpp::Model.new(model_path: model_path, params: params)
      context = ::LLaMACpp::Context.new(model: model)

      embedding_input = context.tokenize(text: text, add_bos: true)

      return unless embedding_input.size.positive?

      context.eval(tokens: embedding_input, n_past: 0, n_threads: n_threads)

      context.embeddings
    end

    private

    # Use the maximum number of GPU layers available
    def n_gpu_layers
      `ioreg -l | grep gpu-core-count`
        .split("=")
        .last
        .strip
        .to_i
    end

    # Use the maximum number of CPU threads available
    def n_threads
      `sysctl -n hw.ncpu`.strip.to_i
    end
  end
end

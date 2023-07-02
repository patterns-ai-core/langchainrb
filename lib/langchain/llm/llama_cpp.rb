# frozen_string_literal: true

module Langchain::LLM
  class LlamaCpp < Base
    attr_accessor :model_path, :n_gpu_layers, :n_ctx
    attr_writer :n_threads

    def initialize(model_path:, n_gpu_layers: 1, n_ctx: 2048, n_threads: 1)
      depends_on "llama_cpp"
      require "llama_cpp"

      @model_path = model_path
      @n_gpu_layers = n_gpu_layers
      @n_ctx = n_ctx
      @n_threads = n_threads
    end

    def n_threads
      # Use the maximum number of CPU threads available, if not configured
      @n_threads ||= `sysctl -n hw.ncpu`.strip.to_i
    end

    def complete(prompt:, n_predict: 128, n_seed: -1, **params)
      params = ::LLaMACpp::ContextParams.new
      params.seed = n_seed
      params.n_ctx = n_ctx
      params.n_gpu_layers = n_gpu_layers

      model = ::LLaMACpp::Model.new(model_path: model_path, params: params)
      context = ::LLaMACpp::Context.new(model: model)

      ::LLaMACpp.generate(context, prompt, n_threads: n_threads, n_predict: n_predict)
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
  end
end

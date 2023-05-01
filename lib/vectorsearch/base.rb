# frozen_string_literal: true

module Vectorsearch
  class Base
    extend Forwardable

    attr_reader :client, :index_name, :llm, :llm_api_key, :llm_client

    DEFAULT_METRIC = "cosine".freeze

    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    def initialize(llm:, llm_api_key:)
      validate_llm!(llm: llm)

      @llm = llm
      @llm_api_key = llm_api_key

      @llm_client = LLM.const_get(LLM::Base::LLMS.fetch(llm)).new(api_key: llm_api_key)
    end

    def create_default_schema
      raise NotImplementedError
    end

    def add_texts(texts:)
      raise NotImplementedError
    end

    # NotImplementedError will be raised if the subclass does not implement this method
    def ask(question:)
      raise NotImplementedError
    end

    def_delegators :llm_client,
      :generate_embedding,
      :generate_completion,
      :default_dimension

    # def generate_embedding(text:)
    #   llm_client.embed(text: text)
    # end

    # def generate_completion(prompt:)
    #   llm_client.complete(prompt: prompt)
    # end

    # def default_dimension
    #   llm_client.default_dimension
    # end

    def generate_prompt(question:, context:)
      "Context:\n" +
      "#{context}\n" +
      "---\n" +
      "Question: #{question}\n" +
      "---\n" +
      "Answer:"
    end

    private

    def validate_llm!(llm:)
      # TODO: Fix that this works is string `llm` value is passed in instead of symbol
      unless LLM::Base::LLMS.keys.include?(llm)
        raise ArgumentError, "LLM must be one of #{LLMS}"
      end
    end
  end
end
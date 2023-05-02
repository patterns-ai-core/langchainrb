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
      # TODO: Fix so this works when `llm` value is a string instead of a symbol
      unless LLM::Base::LLMS.keys.include?(llm)
        raise ArgumentError, "LLM must be one of #{LLM::Base::LLMS.keys}"
      end
    end
  end
end
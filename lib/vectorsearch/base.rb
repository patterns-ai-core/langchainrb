# frozen_string_literal: true

require "forwardable"

module Vectorsearch
  class Base
    extend Forwardable

    attr_reader :client, :index_name, :llm, :llm_api_key, :llm_client

    DEFAULT_METRIC = "cosine"

    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    def initialize(llm:, llm_api_key:)
      LLM::Base.validate_llm!(llm: llm)

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
      prompt_template = Prompt::FewShotPromptTemplate.new(
        prefix: "Context:",
        suffix: "---\nQuestion: {question}\n---\nAnswer:",
        example_prompt: Prompt::PromptTemplate.new(
          template: "{context}",
          input_variables: ["context"]
        ),
        examples: [
          {context: context}
        ],
        input_variables: ["question"],
        example_separator: "\n"
      )

      prompt_template.format(question: question)
    end
  end
end

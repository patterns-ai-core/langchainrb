# frozen_string_literal: true

require "forwardable"

module Langchain::Vectorsearch
  class Base
    include Langchain::DependencyHelper
    extend Forwardable

    attr_reader :client, :index_name, :llm

    DEFAULT_METRIC = "cosine"

    # @param llm [Object] The LLM client to use
    def initialize(llm:)
      @llm = llm
    end

    # Method supported by Vectorsearch DB to create a default schema
    def create_default_schema
      raise NotImplementedError, "#{self.class.name} does not support creating a default schema"
    end

    # Method supported by Vectorsearch DB to add a list of texts to the index
    def add_texts(...)
      raise NotImplementedError, "#{self.class.name} does not support adding texts"
    end

    # Method supported by Vectorsearch DB to search for similar texts in the index
    def similarity_search(...)
      raise NotImplementedError, "#{self.class.name} does not support similarity search"
    end

    # Method supported by Vectorsearch DB to search for similar texts in the index by the passed in vector.
    # You must generate your own vector using the same LLM that generated the embeddings stored in the Vectorsearch DB.
    def similarity_search_by_vector(...)
      raise NotImplementedError, "#{self.class.name} does not support similarity search by vector"
    end

    # Method supported by Vectorsearch DB to answer a question given a context (data) pulled from your Vectorsearch DB.
    def ask(...)
      raise NotImplementedError, "#{self.class.name} does not support asking questions"
    end

    def_delegators :llm,
      :default_dimension

    def generate_prompt(question:, context:)
      prompt_template = Langchain::Prompt::FewShotPromptTemplate.new(
        prefix: "Context:",
        suffix: "---\nQuestion: {question}\n---\nAnswer:",
        example_prompt: Langchain::Prompt::PromptTemplate.new(
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

    def add_data(paths:)
      raise ArgumentError, "Paths must be provided" if paths.to_a.empty?

      texts = Array(paths)
        .flatten
        .map { |path| Langchain::Loader.new(path)&.load&.value }
        .compact

      add_texts(texts: texts)
    end
  end
end

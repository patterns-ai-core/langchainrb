# frozen_string_literal: true

module Langchain::Vectorsearch
  class Pgvector < Base
    #
    # The PostgreSQL vector search adapter
    #
    # Gem requirements:
    #     gem "pgvector", "~> 0.2"
    #
    # Usage:
    #     pgvector = Langchain::Vectorsearch::Pgvector.new(llm:, model_name:)
    #

    # The operators supported by the PostgreSQL vector search adapter
    OPERATORS = [
      "cosine",
      "euclidean",
      "inner_product"
    ]
    DEFAULT_OPERATOR = "cosine"

    attr_reader :db, :operator, :llm
    attr_accessor :model

    # @param url [String] The URL of the PostgreSQL database
    # @param index_name [String] The name of the table to use for the index
    # @param llm [Object] The LLM client to use
    # @param namespace [String] The namespace to use for the index when inserting/querying
    def initialize(llm:)
      depends_on "pgvector"
      depends_on "neighbor"

      @operator = DEFAULT_OPERATOR

      super(llm: llm)
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The texts to add to the index
    # @param ids [Array<String>] The ids to add to the index, in the same order as the texts
    # @return [Array<Integer>] The the ids of the added texts.
    def add_texts(texts:, ids:)
      embeddings = texts.map do |text|
        llm.embed(text: text).embedding
      end

      model.find_each.with_index do |record, i|
        record.update_column(:embedding, embeddings[i])
      end
    end

    def update_texts(texts:, ids:)
      add_texts(texts: texts, ids: ids)
    end

    # Invoke a rake task that will create an initializer (`config/initializers/langchain.rb`) file
    # and db/migrations/* files
    def create_default_schema
      Rake::Task["pgvector"].invoke
    end

    # Destroy default schema
    def destroy_default_schema
      # Tell the user to rollback the migration
    end

    # Search for similar texts in the index
    # @param query [String] The text to search for
    # @param k [Integer] The number of top results to return
    # @return [Array<Hash>] The results of the search
    def similarity_search(query:, k: 4)
      embedding = llm.embed(text: query).embedding

      similarity_search_by_vector(
        embedding: embedding,
        k: k
      )
    end

    # Search for similar texts in the index by the passed in vector.
    # You must generate your own vector using the same LLM that generated the embeddings stored in the Vectorsearch DB.
    # @param embedding [Array<Float>] The vector to search for
    # @param k [Integer] The number of top results to return
    # @return [Array<Hash>] The results of the search
    def similarity_search_by_vector(embedding:, k: 4)
      model
        .nearest_neighbors(:embedding, embedding, distance: operator)
        .limit(k)
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map do |result|
        result.as_vector
      end
      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      llm.chat(prompt: prompt, &block)
    end
  end
end

# Rails connection when configuring vectorsearch
# Update READMEs
# Rails migration to create a migration

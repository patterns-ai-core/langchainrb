# frozen_string_literal: true

module Langchain::Vectorsearch
  class Pgvector < Base
    #
    # The PostgreSQL vector search adapter
    #
    # Gem requirements:
    #     gem "sequel", "~> 5.87.0"
    #     gem "pgvector", "~> 0.2"
    #
    # Usage:
    #     pgvector = Langchain::Vectorsearch::Pgvector.new(url:, index_name:, llm:, namespace: nil)
    #

    # The operators supported by the PostgreSQL vector search adapter
    OPERATORS = {
      "cosine_distance" => "cosine",
      "euclidean_distance" => "euclidean",
      "inner_product_distance" => "inner_product"
    }
    DEFAULT_OPERATOR = "cosine_distance"

    attr_reader :db, :operator, :table_name, :namespace_column, :namespace, :documents_table

    # @param url [String] The URL of the PostgreSQL database
    # @param index_name [String] The name of the table to use for the index
    # @param llm [Object] The LLM client to use
    # @param namespace [String] The namespace to use for the index when inserting/querying
    def initialize(url:, index_name:, llm:, namespace: nil)
      depends_on "sequel"
      depends_on "pgvector"

      @db = Sequel.connect(url)

      @table_name = index_name

      @namespace_column = "namespace"
      @namespace = namespace
      @operator = OPERATORS[DEFAULT_OPERATOR]

      super(llm: llm)
    end

    def documents_model
      Class.new(Sequel::Model(table_name.to_sym)) do
        plugin :pgvector, :vectors
      end
    end

    # Upsert a list of texts to the index
    # @param texts [Array<String>] The texts to add to the index
    # @param ids [Array<Integer>] The ids of the objects to add to the index, in the same order as the texts
    # @param metadata [Hash] The metadata to use for the texts
    # @return [PG::Result] The response from the database including the ids of
    # the added or updated texts.
    def upsert_texts(texts:, ids:, metadata: nil)
      data = texts.zip(ids).flat_map do |(text, id)|
        enriched_text = enrich_text_with_metadata(text,
                                                  metadata: metadata,
                                                  embed_metadata_keys: embed_metadata_keys)
        {
          id: id,
          content: text,
          vectors: llm.embed(text: enriched_text).embedding.to_s,
          namespace: namespace,
          metadata: metadata
        }
      end

      @db[table_name.to_sym]
        .insert_conflict(
          target: :id,
          update: {content: Sequel[:excluded][:content], vectors: Sequel[:excluded][:vectors], metadata: Sequel[:excluded][:metadata]}
        )
        .multi_insert(data, return: :primary_key)
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The texts to add to the index
    # @param ids [Array<String>] The ids to add to the index, in the same order as the texts
    # @param metadata [Hash] The metadata to use for the texts
    # @param embedding_metadata_keys [Array<String>] The keys to use for the metadata when generating embeddings
    # @return [Array<Integer>] The ids of the added texts.
    def add_texts(texts:, ids: nil, metadata: nil, embed_metadata_keys: nil)
      if ids.nil? || ids.empty?
        data = texts.map do |text|
          # Concatenate relevant metadata to the text
          enriched_text = enrich_text_with_metadata(text,
                                                    metadata: metadata,
                                                    embed_metadata_keys: embed_metadata_keys)
          {
            content: text,
            vectors: llm.embed(text: enriched_text).embedding.to_s,
            namespace: namespace,
            metadata: metadata.to_json
          }
        end

        @db[table_name.to_sym].multi_insert(data, return: :primary_key)
      else
        upsert_texts(texts: texts, ids: ids, metadata: metadata.to_json)
      end
    end

    # Update a list of ids and corresponding texts to the index
    # @param texts [Array<String>] The texts to add to the index
    # @param ids [Array<String>] The ids to add to the index, in the same order as the texts
    # @return [Array<Integer>] The ids of the updated texts.
    def update_texts(texts:, ids:, metadata: nil)
      upsert_texts(texts: texts, ids: ids, metadata: metadata.to_json)
    end

    # Remove a list of texts from the index
    # @param ids [Array<Integer>] The ids of the texts to remove from the index
    # @return [Integer] The number of texts removed from the index
    def remove_texts(ids:)
      @db[table_name.to_sym].where(id: ids).delete
    end

    # Create default schema
    def create_default_schema
      db.run "CREATE EXTENSION IF NOT EXISTS vector"
      namespace_column = @namespace_column
      vector_dimensions = llm.default_dimensions
      db.create_table? table_name.to_sym do
        primary_key :id
        text :content
        column :vectors, "vector(#{vector_dimensions})"
        text namespace_column.to_sym, default: nil
        jsonb :metadata
      end
    end

    # Destroy default schema
    def destroy_default_schema
      db.drop_table? table_name.to_sym
    end

    # Search for similar texts in the index
    # @param query [String] The text to search for
    # @param k [Integer] The number of top results to return
    # @param metadata_filter [Hash] The metadata to filter the results by
    # @return [Array<Hash>] The results of the search
    def similarity_search(query:, k: 4, metadata_filter: {})
      embedding = llm.embed(text: query).embedding

      similarity_search_by_vector(
        embedding: embedding,
        k: k,
        metadata_filter: metadata_filter
      )
    end

    # Search for similar texts in the index by the passed in vector.
    # You must generate your own vector using the same LLM that generated the embeddings stored in the Vectorsearch DB.
    # @param embedding [Array<Float>] The vector to search for
    # @param k [Integer] The number of top results to return
    # @return [Array<Hash>] The results of the search
    def similarity_search_by_vector(embedding:, k: 4, metadata_filter: {})
      results =
        db.transaction do # BEGIN
          documents_model
            .nearest_neighbors(:vectors, embedding, distance: operator).limit(k)
            .where(namespace_column.to_sym => namespace)
        end

      return results if metadata_filter.empty?

      results.filter_map do |result|
        metadata = JSON.parse(result.metadata)
        result if metadata_filter.all? { |key, value| metadata[key.to_s] == value }
      end
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map do |result|
        result.content.to_s
      end
      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &block)

      response.context = context
      response
    end

    # Add data from a list of paths
    # @param paths [Array<String>] The paths to load data from
    # @param options [Hash] The options to pass to the loader
    # @param chunker [Object] The chunker to use
    # @param metadata [Hash] The metadata to use for the texts
    def add_data(paths:, options: {}, chunker: Langchain::Chunker::Text, metadata: nil)
      raise ArgumentError, "Paths must be provided" if Array(paths).empty?

      add_texts(texts: texts_from_paths(paths:, options:, chunker:), metadata: metadata)
    end

    private

    # Add metadata context to text. If embedding_metadata_keys are provided, only include those keys in the context
    # otherwise include all metadata keys.
    #
    # @param text [String] The text to enrich
    # @param metadata [Hash] The metadata to add to the text
    # @param embedding_metadata_keys [Array<String>] The keys to use for the metadata when generating embeddings
    # @return [String] The enriched text
    def enrich_text_with_metadata(text, metadata:, embed_metadata_keys:)
      return text unless metadata

      embed_metadata_keys ||= []

      # Select metadata relevant to the context
      selected_metadata_keys = (metadata.keys & embed_metadata_keys) || metadata.keys

      context = selected_metadata_keys.filter_map do |field|
        value = metadata[field]
        "#{field}: #{value}" if value
      end

      # Add metadata context to text
      [context.join("\n"), text].join("\n\n").strip
    end
  end
end

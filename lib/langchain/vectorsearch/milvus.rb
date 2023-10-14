# frozen_string_literal: true

module Langchain::Vectorsearch
  class Milvus < Base
    #
    # Wrapper around Milvus REST APIs.
    #
    # Gem requirements: gem "milvus", "~> 0.9.2"
    #
    # Usage:
    # milvus = Langchain::Vectorsearch::Milvus.new(url:, index_name:, llm:, api_key:)
    #

    def initialize(url:, index_name:, llm:, api_key: nil)
      depends_on "milvus"

      @client = ::Milvus::Client.new(url: url)
      @index_name = index_name

      super(llm: llm)
    end

    def add_texts(texts:)
      client.entities.insert(
        collection_name: index_name,
        num_rows: Array(texts).size,
        fields_data: [
          {
            field_name: "content",
            type: ::Milvus::DATA_TYPES["varchar"],
            field: Array(texts)
          }, {
            field_name: "vectors",
            type: ::Milvus::DATA_TYPES["float_vector"],
            field: Array(texts).map { |text| llm.embed(text: text).embedding }
          }
        ]
      )
    end

    # TODO: Add update_texts method

    # Create default schema
    # @return [Hash] The response from the server
    def create_default_schema
      client.collections.create(
        auto_id: true,
        collection_name: index_name,
        description: "Default schema created by langchain.rb",
        fields: [
          {
            name: "id",
            is_primary_key: true,
            autoID: true,
            data_type: ::Milvus::DATA_TYPES["int64"]
          }, {
            name: "content",
            is_primary_key: false,
            data_type: ::Milvus::DATA_TYPES["varchar"],
            type_params: [
              {
                key: "max_length",
                value: "32768" # Largest allowed value
              }
            ]
          }, {
            name: "vectors",
            data_type: ::Milvus::DATA_TYPES["float_vector"],
            is_primary_key: false,
            type_params: [
              {
                key: "dim",
                value: default_dimension.to_s
              }
            ]
          }
        ]
      )
    end

    # Create the default index
    # @return [Boolean] The response from the server
    def create_default_index
      client.indices.create(
        collection_name: "Documents",
        field_name: "vectors",
        extra_params: [
          {key: "metric_type", value: "L2"},
          {key: "index_type", value: "IVF_FLAT"},
          {key: "params", value: "{\"nlist\":1024}"}
        ]
      )
    end

    # Get the default schema
    # @return [Hash] The response from the server
    def get_default_schema
      client.collections.get(collection_name: index_name)
    end

    # Delete default schema
    # @return [Hash] The response from the server
    def destroy_default_schema
      client.collections.delete(collection_name: index_name)
    end

    # Load default schema into memory
    # @return [Boolean] The response from the server
    def load_default_schema
      client.collections.load(collection_name: index_name)
    end

    def similarity_search(query:, k: 4)
      embedding = llm.embed(text: query).embedding

      similarity_search_by_vector(
        embedding: embedding,
        k: k
      )
    end

    def similarity_search_by_vector(embedding:, k: 4)
      load_default_schema

      client.search(
        collection_name: index_name,
        output_fields: ["id", "content", "vectors"],
        top_k: k.to_s,
        vectors: [embedding],
        dsl_type: 1,
        params: "{\"nprobe\": 10}",
        anns_field: "vectors",
        metric_type: "L2",
        vector_type: ::Milvus::DATA_TYPES["float_vector"]
      )
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      content_field = search_results.dig("results", "fields_data").select { |field| field.dig("field_name") == "content" }
      content_data = content_field.first.dig("Field", "Scalars", "Data", "StringData", "data")

      context = content_data.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      llm.chat(prompt: prompt, &block)
    end
  end
end

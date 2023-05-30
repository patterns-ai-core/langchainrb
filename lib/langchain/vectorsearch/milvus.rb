# frozen_string_literal: true

module Langchain
  module Vectorsearch
    class Milvus < Base
      def initialize(url:, index_name:, llm:, llm_api_key:, api_key: nil)
        depends_on "milvus"
        require "milvus"

        @client = ::Milvus::Client.new(url: url)
        @index_name = index_name

        super(llm: llm, llm_api_key: llm_api_key)
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
              type: ::Milvus::DATA_TYPES["binary_vector"],
              field: Array(texts).map { |text| llm_client.embed(text: text) }
            }
          ]
        )
      end

      # Create default schema
      # @return [Hash] The response from the server
      def create_default_schema
        client.collections.create(
          auto_id: true,
          collection_name: index_name,
          description: "Default schema created by Vectorsearch",
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
              data_type: ::Milvus::DATA_TYPES["binary_vector"],
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

      def similarity_search(query:, k: 4)
        embedding = llm_client.embed(text: query)

        similarity_search_by_vector(
          embedding: embedding,
          k: k
        )
      end

      def similarity_search_by_vector(embedding:, k: 4)
        client.search(
          collection_name: index_name,
          top_k: k.to_s,
          vectors: [embedding],
          dsl_type: 1,
          params: "{\"nprobe\": 10}",
          anns_field: "content",
          metric_type: "L2"
        )
      end
    end
  end
end

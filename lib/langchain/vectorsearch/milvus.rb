# frozen_string_literal: true

module Langchain::Vectorsearch
  class Milvus < Base
    #
    # Wrapper around Milvus REST APIs.
    #
    # Gem requirements:
    #     gem "milvus", "~> 0.10.3"
    #
    # Usage:
    #     milvus = Langchain::Vectorsearch::Milvus.new(url:, index_name:, llm:, api_key:)
    #
    def initialize(url:, index_name:, llm:, api_key: nil)
      depends_on "milvus"

      @client = ::Milvus::Client.new(
        url: url,
        logger: Langchain.logger
      )
      @index_name = index_name

      super(llm: llm)
    end

    def add_texts(texts:)
      client.entities.insert(
        collection_name: index_name,
        data: texts.map do |text|
          {content: text, vector: llm.embed(text: text).embedding}
        end
      )
    end

    # TODO: Add update_texts method

    # Deletes a list of texts in the index
    #
    # @param ids [Array<Integer>] The ids of texts to delete
    # @return [Boolean] The response from the server
    def remove_texts(ids:)
      raise ArgumentError, "ids must be an array" unless ids.is_a?(Array)

      client.entities.delete(
        collection_name: index_name,
        filter: "id in #{ids}"
      )
    end

    # TODO: Add update_texts method

    # Create default schema
    # @return [Hash] The response from the server
    def create_default_schema
      client.collections.create(
        auto_id: true,
        collection_name: index_name,
        fields: [
          {
            fieldName: "id",
            isPrimary: true,
            dataType: "Int64"
          }, {
            fieldName: "content",
            isPrimary: false,
            dataType: "VarChar",
            elementTypeParams: {
              max_length: "32768" # Largest allowed value
            }
          }, {
            fieldName: "vector",
            isPrimary: false,
            dataType: "FloatVector",
            elementTypeParams: {
              dim: llm.default_dimensions.to_s
            }
          }
        ]
      )
    end

    # Create the default index
    # @return [Boolean] The response from the server
    def create_default_index
      client.indexes.create(
        collection_name: index_name,
        index_params: [
          {
            metricType: "L2",
            fieldName: "vector",
            indexName: "vector_idx",
            indexConfig: {
              index_type: "AUTOINDEX"
            }
          }
        ]
      )
    end

    # Get the default schema
    # @return [Hash] The response from the server
    def get_default_schema
      client.collections.describe(collection_name: index_name)
    end

    # Delete default schema
    # @return [Hash] The response from the server
    def destroy_default_schema
      client.collections.drop(collection_name: index_name)
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

      client.entities.search(
        collection_name: index_name,
        anns_field: "vector",
        data: [embedding],
        limit: k,
        output_fields: ["content", "id", "vector"]
      )
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      content_data = search_results.dig("data").map { |result| result.dig("content") }

      context = content_data.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &block)

      response.context = context
      response
    end
  end
end

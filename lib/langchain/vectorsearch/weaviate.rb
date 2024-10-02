# frozen_string_literal: true

module Langchain::Vectorsearch
  class Weaviate < Base
    #
    # Wrapper around Weaviate
    #
    # Gem requirements:
    #     gem "weaviate-ruby", "~> 0.9.2"
    #
    # Usage:
    #     weaviate = Langchain::Vectorsearch::Weaviate.new(url: ENV["WEAVIATE_URL"], api_key: ENV["WEAVIATE_API_KEY"], index_name: "Docs", llm: llm)
    #

    # Initialize the Weaviate adapter
    # @param url [String] The URL of the Weaviate instance
    # @param api_key [String] The API key to use
    # @param index_name [String] The capitalized name of the index to use
    # @param llm [Object] The LLM client to use
    def initialize(url:, index_name:, llm:, api_key: nil)
      depends_on "weaviate-ruby", req: "weaviate"

      @client = ::Weaviate::Client.new(
        url: url,
        api_key: api_key,
        logger: Langchain.logger
      )

      # Weaviate requires the class name to be Capitalized: https://weaviate.io/developers/weaviate/configuration/schema-configuration#create-a-class
      # TODO: Capitalize index_name
      @index_name = index_name

      super(llm: llm)
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The list of texts to add
    # @return [Hash] The response from the server
    def add_texts(texts:, ids: [])
      client.objects.batch_create(
        objects: weaviate_objects(texts, ids)
      )
    end

    # Update a list of texts in the index
    # @param texts [Array<String>] The list of texts to update
    # @return [Hash] The response from the server
    def update_texts(texts:, ids:)
      uuids = []

      # Retrieve the UUIDs of the objects to update
      Array(texts).map.with_index do |text, i|
        record = client.query.get(
          class_name: index_name,
          fields: "_additional { id }",
          where: "{ path: [\"__id\"], operator: Equal, valueString: \"#{ids[i]}\" }"
        )
        uuids.push record[0].dig("_additional", "id")
      end

      # Update the objects
      texts.map.with_index do |text, i|
        client.objects.update(
          class_name: index_name,
          id: uuids[i],
          properties: {
            __id: ids[i].to_s,
            content: text
          },
          vector: llm.embed(text: text).embedding
        )
      end
    end

    # Deletes a list of texts in the index
    # @param ids [Array] The ids of texts to delete
    # @return [Hash] The response from the server
    def remove_texts(ids:)
      raise ArgumentError, "ids must be an array" unless ids.is_a?(Array)

      client.objects.batch_delete(
        class_name: index_name,
        where: {
          path: ["__id"],
          operator: "ContainsAny",
          valueTextArray: ids
        }
      )
    end

    # Create default schema
    # @return [Hash] The response from the server
    def create_default_schema
      client.schema.create(
        class_name: index_name,
        vectorizer: "none",
        properties: [
          # __id to be used a pointer to the original document
          {dataType: ["string"], name: "__id"}, # '_id' is a reserved property name (single underscore)
          {dataType: ["text"], name: "content"}
        ]
      )
    end

    # Get default schema
    # @return [Hash] The response from the server
    def get_default_schema
      client.schema.get(class_name: index_name)
    end

    # Delete the index
    # @return [Boolean] Whether the index was deleted
    def destroy_default_schema
      client.schema.delete(class_name: index_name)
    end

    # Return documents similar to the query
    # @param query [String] The query to search for
    # @param k [Integer|String] The number of results to return
    # @return [Hash] The search results
    def similarity_search(query:, k: 4)
      embedding = llm.embed(text: query).embedding

      similarity_search_by_vector(embedding: embedding, k: k)
    end

    # Return documents similar to the vector
    # @param embedding [Array<Float>] The vector to search for
    # @param k [Integer|String] The number of results to return
    # @return [Hash] The search results
    def similarity_search_by_vector(embedding:, k: 4)
      near_vector = "{ vector: #{embedding} }"

      client.query.get(
        class_name: index_name,
        near_vector: near_vector,
        limit: k.to_s,
        fields: "__id content _additional { id }"
      )
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [Hash] The answer
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map do |result|
        result.dig("content").to_s
      end
      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &block)

      response.context = context
      response
    end

    private

    def weaviate_objects(texts, ids = [])
      Array(texts).map.with_index do |text, i|
        weaviate_object(text, ids[i])
      end
    end

    def weaviate_object(text, id = nil)
      {
        class: index_name,
        properties: {
          __id: id.to_s,
          content: text
        },
        vector: llm.embed(text: text).embedding
      }
    end
  end
end

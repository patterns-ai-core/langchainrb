# frozen_string_literal: true

module Langchain::Vectorsearch
  class Qdrant < Base
    #
    # Wrapper around Qdrant
    #
    # Gem requirements:
    #     gem "qdrant-ruby", "~> 0.9.8"
    #
    # Usage:
    #     qdrant = Langchain::Vectorsearch::Qdrant.new(url:, api_key:, index_name:, llm:)
    #

    # Initialize the Qdrant client
    # @param url [String] The URL of the Qdrant server
    # @param api_key [String] The API key to use
    # @param index_name [String] The name of the index to use
    # @param llm [Object] The LLM client to use
    def initialize(url:, api_key:, index_name:, llm:)
      depends_on "qdrant-ruby", req: "qdrant"

      @client = ::Qdrant::Client.new(
        url: url,
        api_key: api_key,
        logger: Langchain.logger
      )
      @index_name = index_name

      super(llm: llm)
    end

    # Find records by ids
    # @param ids [Array<Integer>] The ids to find
    # @return [Hash] The response from the server
    def find(ids: [])
      client.points.get_all(
        collection_name: index_name,
        ids: ids,
        with_payload: true,
        with_vector: true
      )
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The list of texts to add
    # @return [Hash] The response from the server
    def add_texts(texts:, ids: [], payload: {})
      batch = {ids: [], vectors: [], payloads: []}

      Array(texts).each_with_index do |text, i|
        id = ids[i] || SecureRandom.uuid
        batch[:ids].push(id)
        batch[:vectors].push(llm.embed(text: text).embedding)
        batch[:payloads].push({content: text}.merge(payload))
      end

      client.points.upsert(
        collection_name: index_name,
        batch: batch
      )
    end

    def update_texts(texts:, ids:)
      add_texts(texts: texts, ids: ids)
    end

    # Remove a list of texts from the index
    # @param ids [Array<Integer>] The ids to remove
    # @return [Hash] The response from the server
    def remove_texts(ids:)
      client.points.delete(
        collection_name: index_name,
        points: ids
      )
    end

    # Get the default schema
    # @return [Hash] The response from the server
    def get_default_schema
      client.collections.get(collection_name: index_name)
    end

    # Deletes the default schema
    # @return [Hash] The response from the server
    def destroy_default_schema
      client.collections.delete(collection_name: index_name)
    end

    # Create the index with the default schema
    # @return [Hash] The response from the server
    def create_default_schema
      client.collections.create(
        collection_name: index_name,
        vectors: {
          distance: DEFAULT_METRIC.capitalize,
          size: llm.default_dimensions
        }
      )
    end

    # Search for similar texts
    # @param query [String] The text to search for
    # @param k [Integer] The number of results to return
    # @return [Hash] The response from the server
    def similarity_search(
      query:,
      k: 4
    )
      embedding = llm.embed(text: query).embedding

      similarity_search_by_vector(
        embedding: embedding,
        k: k
      )
    end

    # Search for similar texts by embedding
    # @param embedding [Array<Float>] The embedding to search for
    # @param k [Integer] The number of results to return
    # @return [Hash] The response from the server
    def similarity_search_by_vector(
      embedding:,
      k: 4
    )
      response = client.points.search(
        collection_name: index_name,
        limit: k,
        vector: embedding,
        with_payload: true,
        with_vector: true
      )
      response.dig("result")
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map do |result|
        result.dig("payload").to_s
      end
      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &block)

      response.context = context
      response
    end
  end
end

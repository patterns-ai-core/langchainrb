# frozen_string_literal: true

module Langchain::Vectorsearch
  class Weaviate < Base
    #
    # Wrapper around Weaviate
    #
    # Gem requirements: gem "weaviate-ruby", "~> 0.8.0"
    #
    # Usage:
    # weaviate = Langchain::Vectorsearch::Weaviate.new(url:, api_key:, index_name:, llm:, llm_api_key:)
    #

    # Initialize the Weaviate adapter
    # @param url [String] The URL of the Weaviate instance
    # @param api_key [String] The API key to use
    # @param index_name [String] The name of the index to use
    # @param llm [Object] The LLM client to use
    def initialize(url:, api_key:, index_name:, llm:)
      depends_on "weaviate-ruby"
      require "weaviate"

      @client = ::Weaviate::Client.new(
        url: url,
        api_key: api_key
      )
      @index_name = index_name

      super(llm: llm)
    end

    # Add a list of texts to the index
    # @param texts [Array] The list of texts to add
    # @return [Hash] The response from the server
    def add_texts(texts:)
      objects = Array(texts).map do |text|
        {
          class: index_name,
          properties: {content: text},
          vector: llm.embed(text: text)
        }
      end

      client.objects.batch_create(
        objects: objects
      )
    end

    # Create default schema
    def create_default_schema
      client.schema.create(
        class_name: index_name,
        vectorizer: "none",
        properties: [
          # TODO: Allow passing in your own IDs
          {
            dataType: ["text"],
            name: "content"
          }
        ]
      )
    end

    # Return documents similar to the query
    # @param query [String] The query to search for
    # @param k [Integer|String] The number of results to return
    # @param distance [Integer|String] The maximum distance to search for
    # @return [Hash] The search results
    def similarity_search(query:, k: 4, distance: nil)
      if distance
        near_text = "{ concepts: \"#{query}\" distance: #{distance} }"

        client.query.get(
          class_name: index_name,
          near_text: near_text,
          limit: k.to_s,
          fields: "content _additional { id distance}"
        )
      else
        embedding = llm.embed(text: query)

        similarity_search_by_vector(embedding: embedding, k: k)
      end
    end

    # Return documents similar to the vector
    # @param embedding [Array] The vector to search for
    # @param k [Integer|String] The number of results to return
    # @return [Hash] The search results
    def similarity_search_by_vector(embedding:, k: 4)
      near_vector = "{ vector: #{embedding} }"

      client.query.get(
        class_name: index_name,
        near_vector: near_vector,
        limit: k.to_s,
        fields: "content _additional { id }"
      )
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @return [Hash] The answer
    def ask(question:)
      search_results = similarity_search(query: question)

      context = search_results.map do |result|
        result.dig("content").to_s
      end
      context = context.join("\n---\n")

      prompt = generate_prompt(question: question, context: context)

      llm.chat(prompt: prompt)
    end
  end
end

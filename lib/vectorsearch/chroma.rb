# frozen_string_literal: true

module Vectorsearch
  class Chroma < Base
    # Initialize the Chroma client
    # @param url [String] The URL of the Qdrant server
    # @param api_key [String] The API key to use
    # @param index_name [String] The name of the index to use
    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    def initialize(url:, api_key: nil, index_name:, llm:, llm_api_key:)
      depends_on "chroma-db"
      require "chroma-db"

      Chroma.connect_host = url
      Chroma.logger = Langchain.logger
      Chroma.log_level = Langchain.logger.level

      @index_name = index_name

      super(llm: llm, llm_api_key: llm_api_key)
    end

    # Add a list of texts to the index
    # @param texts [Array] The list of texts to add
    # @return [Hash] The response from the server
    def add_texts(texts:)
      embeddings = texts.map do |text|
        Chroma::Resources::Embedding.new(
          # TODO: Add support for passing your own IDs
          id: SecureRandom.uuid, 
          embedding: llm_client.embed(text),
          # TODO: Add support for passing metadata
          # metadata: metadatas[index],
          document: text # Do we actually need to store the whole original document?
        )
      end

      collection = Chroma::Resources::Collection.get(index_name)
      collection.add(embeddings)
    end

    # Create the collection with the default schema
    # @return [Hash] The response from the server
    def create_default_schema
      collection = Chroma::Resources::Collection.create(index_name)
    end

    # Search for similar texts
    # @param query [String] The text to search for
    # @param k [Integer] The number of results to return
    # @return [Hash] The response from the server
    def similarity_search(
      query:,
      k: 4
    )
      embedding = llm_client.embed(text: query)

      similarity_search_by_vector(
        embedding: embedding,
        k: k
      )
    end

    # Search for similar texts by embedding
    # @param embedding [Array] The embedding to search for
    # @param k [Integer] The number of results to return
    # @return [Hash] The response from the server
    def similarity_search_by_vector(
      embedding:,
      k: 4
    )
      collection.query(query_embeddings: [embedding], results: k)
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @return [String] The answer to the question
    def ask(question:)
      search_results = similarity_search(query: question)

      context = search_results.dig("result").map do |result|
        result.dig("payload").to_s
      end
      context = context.join("\n---\n")

      prompt = generate_prompt(question: question, context: context)

      llm_client.chat(prompt: prompt)
    end

    private

    # @return [Chroma::Resources::Collection] The collection
    def collection
      @collection ||= Chroma::Resources::Collection.get(index_name)
    end
  end
end

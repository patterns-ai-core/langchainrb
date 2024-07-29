# frozen_string_literal: true

module Langchain::Vectorsearch
  class Chroma < Base
    #
    # Wrapper around Chroma DB
    #
    # Gem requirements:
    #     gem "chroma-db", "~> 0.6.0"
    #
    # Usage:
    # chroma = Langchain::Vectorsearch::Chroma.new(url:, index_name:, llm:, api_key: nil)
    #

    # Initialize the Chroma client
    # @param url [String] The URL of the Chroma server
    # @param index_name [String] The name of the index to use
    # @param llm [Object] The LLM client to use
    def initialize(url:, index_name:, llm:)
      depends_on "chroma-db"

      ::Chroma.connect_host = url
      ::Chroma.logger = Langchain.logger
      ::Chroma.log_level = Langchain.logger.level

      @index_name = index_name

      super(llm: llm)
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The list of texts to add
    # @param ids [Array<String>] The list of ids to use for the texts (optional)
    # @param metadatas [Array<Hash>] The list of metadata to use for the texts (optional)
    # @return [Hash] The response from the server
    def add_texts(texts:, ids: [], metadatas: [])
      embeddings = Array(texts).map.with_index do |text, i|
        ::Chroma::Resources::Embedding.new(
          id: ids[i] ? ids[i].to_s : SecureRandom.uuid,
          embedding: llm.embed(text: text).embedding,
          metadata: metadatas[i] || {},
          document: text # Do we actually need to store the whole original document?
        )
      end

      collection = ::Chroma::Resources::Collection.get(index_name)
      collection.add(embeddings)
    end

    def update_texts(texts:, ids:, metadatas: [])
      embeddings = Array(texts).map.with_index do |text, i|
        ::Chroma::Resources::Embedding.new(
          id: ids[i].to_s,
          embedding: llm.embed(text: text).embedding,
          metadata: metadatas[i] || {},
          document: text # Do we actually need to store the whole original document?
        )
      end

      collection.update(embeddings)
    end

    # Remove a list of texts from the index
    # @param ids [Array<String>] The list of ids to remove
    # @return [Hash] The response from the server
    def remove_texts(ids:)
      collection.delete(
        ids: ids.map(&:to_s)
      )
    end

    # Create the collection with the default schema
    # @return [::Chroma::Resources::Collection] Created collection
    def create_default_schema
      ::Chroma::Resources::Collection.create(index_name)
    end

    # Get the default schema
    # @return [::Chroma::Resources::Collection] Default schema
    def get_default_schema
      ::Chroma::Resources::Collection.get(index_name)
    end

    # Delete the default schema
    # @return [bool] Success or failure
    def destroy_default_schema
      ::Chroma::Resources::Collection.delete(index_name)
    end

    # Search for similar texts
    # @param query [String] The text to search for
    # @param k [Integer] The number of results to return
    # @return [Chroma::Resources::Embedding] The response from the server
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
    # @return [Chroma::Resources::Embedding] The response from the server
    def similarity_search_by_vector(
      embedding:,
      k: 4
    )
      # Requesting more results than the number of documents in the collection currently throws an error in Chroma DB
      # Temporary fix inspired by this comment: https://github.com/chroma-core/chroma/issues/301#issuecomment-1520494512
      count = collection.count
      n_results = [count, k].min

      collection.query(query_embeddings: [embedding], results: n_results)
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &block)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map do |result|
        result.document
      end

      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &block)

      response.context = context
      response
    end

    private

    # @return [Chroma::Resources::Collection] The collection
    def collection
      @collection ||= ::Chroma::Resources::Collection.get(index_name)
    end
  end
end

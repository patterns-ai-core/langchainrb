# frozen_string_literal: true

module Langchain::Vectorsearch
  class Hnswlib < Base
    #
    # Wrapper around HNSW (Hierarchical Navigable Small World)
    #
    # Gem requirements: gem "hnswlib", "~> 0.8.1"
    #
    # Usage:
    # hnsw = Langchain::Vectorsearch::Hnswlib.new(url:, index_name:, llm:)
    #

    attr_reader :index

    #
    # Initialize the HNSW vector search
    #
    # @param url [String] The URL of the Qdrant server
    # @param index_name [String] The name of the index to use
    # @param llm [Object] The LLM client to use
    #
    def initialize(llm:, url: nil, index_name: nil)
      depends_on "hnswlib"
      require "hnswlib"

      super(llm: llm)

      @index = ::Hnswlib::HierarchicalNSW.new(space: DEFAULT_METRIC, dim: default_dimension)
      @index.init_index(max_elements: 100_000)
    end

    #
    # Add a list of texts and corresponding IDs to the index
    #
    # @param texts [Array] The list of texts to add
    # @param ids [Array] The list of corresponding IDs (integers) to the texts
    # @return [Boolean] The response from the HNSW library
    #
    def add_texts(texts:, ids:)
      Array(texts).each_with_index do |text, i|
        embedding = llm.embed(text: text)

        index.add_point(embedding, ids[i])
      end
    end

    #
    # Search for the K nearest neighbors of a given vector
    #
    # @param embedding [Array] The embedding to search for
    # @param k [Integer] The number of results to return
    # @return [Array] Results in the format `[[id1, distance3], [id2, distance2]]`
    #
    def similarity_search_by_vector(
      embedding:,
      k: 4
    )
      index.search_knn(embedding, k)
    end
  end
end

# frozen_string_literal: true

module Langchain::Tool
  #
  # A tool wraps vectorsearch classes
  #
  # Usage:
  #    # Initialize the LLM that will be used to generate embeddings
  #    ollama = Langchain::LLM::Ollama.new(url: ENV["OLLAMA_URL"]
  #    chroma = Langchain::Vectorsearch::Chroma.new(url: ENV["CHROMA_URL"], index_name: "my_index", llm: ollama)
  #
  #    # This tool can now be used by the Assistant
  #    vectorsearch_tool = Langchain::Tool::Vectorsearch.new(vectorsearch: chroma)
  #
  class Vectorsearch
    extend Langchain::ToolDefinition

    define_function :similarity_search, description: "Vectorsearch: Retrieves relevant document for the query" do
      property :query, type: "string", description: "Query to find similar documents for", required: true
      property :k, type: "integer", description: "Number of similar documents to retrieve. Default value: 4"
    end

    attr_reader :vectorsearch

    # Initializes the Vectorsearch tool
    #
    # @param vectorsearch [Langchain::Vectorsearch::Base] Vectorsearch instance to use
    def initialize(vectorsearch:)
      @vectorsearch = vectorsearch
    end

    # Executes the vector search and returns the results
    #
    # @param query [String] The query to search for
    # @param k [Integer] The number of results to return
    def similarity_search(query:, k: 4)
      vectorsearch.similarity_search(query:, k: 4)
    end
  end
end

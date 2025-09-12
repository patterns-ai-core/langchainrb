# frozen_string_literal: true

module LangChain::Tool
  #
  # A tool wraps vectorsearch classes
  #
  # Usage:
  #    # Initialize the LLM that will be used to generate embeddings
  #    ollama = LangChain::LLM::Ollama.new(url: ENV["OLLAMA_URL"]
  #    chroma = LangChain::Vectorsearch::Chroma.new(url: ENV["CHROMA_URL"], index_name: "my_index", llm: ollama)
  #
  #    # This tool can now be used by the Assistant
  #    vectorsearch_tool = LangChain::Tool::Vectorsearch.new(vectorsearch: chroma)
  #
  class Vectorsearch
    extend LangChain::ToolDefinition

    define_function :similarity_search, description: "Vectorsearch: Retrieves relevant document for the query" do
      property :query, type: "string", description: "Query to find similar documents for", required: true
      property :k, type: "integer", description: "Number of similar documents to retrieve. Default value: 4"
    end

    attr_reader :vectorsearch

    # Initializes the Vectorsearch tool
    #
    # @param vectorsearch [LangChain::Vectorsearch::Base] Vectorsearch instance to use
    def initialize(vectorsearch:)
      @vectorsearch = vectorsearch
    end

    # Executes the vector search and returns the results
    #
    # @param query [String] The query to search for
    # @param k [Integer] The number of results to return
    # @return [LangChain::Tool::Response] The response from the server
    def similarity_search(query:, k: 4)
      result = vectorsearch.similarity_search(query:, k: 4)
      tool_response(content: result)
    end
  end
end

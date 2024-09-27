# frozen_string_literal: true

module Langchain::Tool
  #
  # Tool that adds the capability to search using the Wikipedia API
  #
  # Gem requirements:
  #     gem "wikipedia-client", "~> 1.17.0"
  #
  # Usage:
  #     wikipedia = Langchain::Tool::Wikipedia.new
  #     wikipedia.execute(input: "The Roman Empire")
  #
  class Wikipedia
    extend Langchain::ToolDefinition
    include Langchain::DependencyHelper

    define_function :execute, description: "Executes Wikipedia API search and returns the answer" do
      property :input, type: "string", description: "Search query", required: true
    end

    # Initializes the Wikipedia tool
    def initialize
      depends_on "wikipedia-client", req: "wikipedia"
    end

    # Executes Wikipedia API search and returns the answer
    #
    # @param input [String] search query
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.debug("#{self.class} - Executing \"#{input}\"")

      page = ::Wikipedia.find(input)
      # It would be nice to figure out a way to provide page.content but the LLM token limit is an issue
      page.summary
    end
  end
end

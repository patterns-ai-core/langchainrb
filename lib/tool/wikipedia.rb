# frozen_string_literal: true

module Tool
  class Wikipedia < Base
    # Tool that adds the capability to search using the Wikipedia API

    description <<~DESC
      A wrapper around Wikipedia.

      Useful for when you need to answer general questions about
      people, places, companies, facts, historical events, or other subjects.

      Input should be a search query.
    DESC

    def initialize
      depends_on "wikipedia-client"
      require "wikipedia"
    end

    # Executes Wikipedia API search and returns the answer
    # @param input [String] search query
    # @return [String] Answer
    def execute(input:)
      page = ::Wikipedia.find(input)
      # It would be nice to figure out a way to provide page.content but the LLM token limit is an issue
      page.summary
    end
  end
end

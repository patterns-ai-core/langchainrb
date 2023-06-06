# frozen_string_literal: true

module Langchain::Tool
  class SerpApi < Base
    #
    # Wrapper around SerpAPI
    #
    # Gem requirements: gem "google_search_results", "~> 2.0.0"
    #
    attr_reader :api_key

    const_set(:NAME, "search")
    description <<~DESC
      A wrapper around Google Search.

      Useful for when you need to answer questions about current events.
      Always one of the first options when you need to find information on internet.

      Input should be a search query.
    DESC

    def initialize(api_key:)
      depends_on "google_search_results"
      require "google_search_results"
      @api_key = api_key
    end

    # Executes Google Search and returns hash_results JSON
    # @param input [String] search query
    # @return [Hash] hash_results JSON

    def self.execute_search(input:)
      new.execute_search(input: input)
    end

    # Executes Google Search and returns hash_results JSON
    # @param input [String] search query
    # @return [String] Answer
    # TODO: Glance at all of the fields that langchain Python looks through: https://github.com/hwchase17/langchain/blob/v0.0.166/langchain/utilities/serpapi.py#L128-L156
    # We may need to do the same thing here.
    def execute(input:)
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing \"#{input}\"")

      hash_results = execute_search(input: input)

      hash_results.dig(:answer_box, :answer) ||
        hash_results.dig(:answer_box, :snippet) ||
        hash_results.dig(:organic_results, 0, :snippet)
    end

    def execute_search(input:)
      GoogleSearch.new(
        q: input,
        serp_api_key: api_key
      ).get_hash
    end
  end
end

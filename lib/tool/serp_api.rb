# frozen_string_literal: true

require "google_search_results"

module Tool
  class SerpApi < Base
    DESCRIPTION = "A wrapper around Google Search. " +
      "Useful for when you need to answer questions about current events. " +
      "Always one of the first options when you need to find information on internet. " +
      "Input should be a search query."

    def self.execute(input:)
      search = GoogleSearch.new(
        q: input,
        serp_api_key: ENV["SERP_API_KEY"]
      )
      hash_results = search.get_hash
      hash_results.dig(:answer_box, :answer) ||
        hash_results.dig(:answer_box, :snippet) ||
        hash_results.dig(:organic_results, 0, :snippet)
    end

    def self.calculate(input:)
      search = GoogleSearch.new(
        q: input,
        serp_api_key: ENV["SERP_API_KEY"]
      )
      hash_results = search.get_hash
      hash_results.dig(:answer_box, :to)
    end
  end
end

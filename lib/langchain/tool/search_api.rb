# frozen_string_literal: true

module Langchain::Tool
  #
  # Wrapper around SearchApi (https://www.searchapi.io), a real-time SERP API
  # for Google and other search engines.
  #
  # Usage:
  #    search_api = Langchain::Tool::SearchApi.new(api_key: ENV["SEARCH_API_API_KEY"])
  #    search_api.search(query: "What is the capital of France?")
  #
  class SearchApi
    extend Langchain::ToolDefinition

    ENDPOINT = "https://www.searchapi.io/api/v1/search"

    # Response keys that describe the request rather than the results
    METADATA_KEYS = %w[search_metadata search_parameters search_information pagination].freeze

    # Result fields that hold images, which an LLM can't read and which can be large base64 strings
    IMAGE_KEYS = %w[favicon thumbnail thumbnails image images].freeze

    define_function :search, description: "SearchApi Tool: Search the web and return the results" do
      property :query, type: "string", description: "The search query string", required: true
      property :num, type: "integer", description: "The number of results to return"
      property :location, type: "string", description: "The geographic location to search from, e.g. \"New York,United States\""
      property :gl, type: "string", description: "The two-letter country code to search from, e.g. \"us\""
      property :hl, type: "string", description: "The two-letter language code of the results, e.g. \"en\""
    end

    attr_reader :api_key, :engine

    #
    # Initializes the SearchApi tool
    #
    # @param api_key [String] SearchApi API key
    # @param engine [String] The search engine to use, e.g. "google", "google_news" or "bing". See https://www.searchapi.io/docs
    # @return [Langchain::Tool::SearchApi] SearchApi tool
    #
    def initialize(api_key:, engine: "google")
      @api_key = api_key
      @engine = engine
    end

    # Search the web for a query.
    #
    # @param query [String] The search query string.
    # @param num [Integer] The number of results to return.
    # @param location [String] The geographic location to search from.
    # @param gl [String] The two-letter country code to search from.
    # @param hl [String] The two-letter language code of the results.
    #
    # @return [Langchain::ToolResponse] The search results in JSON format, without request metadata and images.
    def search(query:, num: nil, location: nil, gl: nil, hl: nil)
      Langchain.logger.debug("#{self.class} - Searching for \"#{query}\"")

      params = {engine: engine, q: query, num: num, location: location, gl: gl, hl: hl}.compact
      uri = URI("#{ENDPOINT}?#{URI.encode_www_form(params)}")

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{api_key}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      results = JSON.parse(response.body)
      return tool_response(content: "SearchApi error: #{results["error"]}") if results["error"]

      tool_response(content: strip_images(results.except(*METADATA_KEYS)).to_json)
    end

    private

    def strip_images(value)
      case value
      when Hash
        value.except(*IMAGE_KEYS).transform_values { |v| strip_images(v) }
      when Array
        value.map { |v| strip_images(v) }
      else
        value
      end
    end
  end
end

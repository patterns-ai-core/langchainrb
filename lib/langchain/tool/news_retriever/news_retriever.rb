# frozen_string_literal: true

module Langchain::Tool
  class NewsRetriever < Base
    #
    # A tool that retrieves latest news from various sources via https://newsapi.org/.
    # An API key needs to be obtained from https://newsapi.org/ to use this tool.
    #
    # Usage:
    #    news_retriever = Langchain::Tool::NewsRetriever.new(api_key: ENV["NEWS_API_KEY"])
    #
    NAME = "news_retriever"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    def initialize(api_key: ENV["NEWS_API_KEY"])
      @api_key = api_key
    end

    def get_everything(
      q: nil,
      search_in: nil,
      sources: nil,
      domains: nil,
      exclude_domains: nil,
      from: nil,
      to: nil,
      language: nil,
      sort_by: nil,
      page_size: nil,
      page: nil
    )
      Langchain.logger.info("Retrieving all news", for: self.class)

      params = {apiKey: @api_key}
      params[:q] = q if q
      params[:searchIn] = search_in if search_in
      params[:sources] = sources if sources
      params[:domains] = domains if domains
      params[:excludeDomains] = exclude_domains if exclude_domains
      params[:from] = from if from
      params[:to] = to if to
      params[:language] = language if language
      params[:sortBy] = sort_by if sort_by
      params[:pageSize] = page_size if page_size
      params[:page] = page if page

      send_request(path: "everything", params: params)
    end

    def get_top_headlines(
      country: nil,
      category: nil,
      sources: nil,
      q: nil,
      page_size: nil,
      page: nil
    )
      Langchain.logger.info("Retrieving top news headlines", for: self.class)

      params = {apiKey: @api_key}
      params[:country] = country if country
      params[:category] = category if category
      params[:sources] = sources if sources
      params[:q] = q if q
      params[:pageSize] = page_size if page_size
      params[:page] = page if page

      send_request(path: "top-headlines", params: params)
    end

    def get_sources(
      category: nil,
      language: nil,
      country: nil
    )
      Langchain.logger.info("Retrieving news sources", for: self.class)

      params = {apiKey: @api_key}
      params[:country] = country if country
      params[:category] = category if category
      params[:language] = language if language

      send_request(path: "top-headlines/sources", params: params)
    end

    private

    def send_request(path:, params:)
      uri = URI.parse("https://newsapi.org/v2/#{path}?#{URI.encode_www_form(params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      response = http.request(request)
      response.body
    end
  end
end

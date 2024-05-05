# frozen_string_literal: true

module Langchain::Tool
  class NewsRetriever < Base
    #
    # A tool that execute Ruby code in a sandboxed environment.
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

      uri = URI.parse("https://newsapi.org/v2/everything?#{URI.encode_www_form(params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      response = http.request(request)
      response.body
    end

    def get_top_headlines(
      country: nil,
      category: nil,
      sources: nil,
      q: nil,
      page_size: nil,
      page: nil
    )
      params = {apiKey: @api_key}
      params[:country] = country if country
      params[:category] = category if category
      params[:sources] = sources if sources
      params[:q] = q if q
      params[:pageSize] = page_size if page_size
      params[:page] = page if page

      uri = URI.parse("https://newsapi.org/v2/top-headlines?#{URI.encode_www_form(params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      response = http.request(request)
      response.body
    end

    def get_sources(
      category: nil,
      language: nil,
      country: nil
    )
      params = {apiKey: @api_key}
      params[:country] = country if country
      params[:category] = category if category
      params[:language] = language if language

      uri = URI.parse("https://newsapi.org/v2/top-headlines/sources?#{URI.encode_www_form(params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      response = http.request(request)
      response.body
    end
  end
end

# frozen_string_literal: true
module Langchain::Vectorsearch
  class Elasticsearch < Base
    attr_accessor :es_client, :index_name

    def initialize(url:, index_name:, llm:, api_key: nil, es_options: {})
      require "elasticsearch"

      options = {
        url: url,
        request_timeout: 20,
        log: false
      }.merge(es_options)

      @es_client = ::Elasticsearch::Client.new(**options)
      @index_name = index_name

      super(llm: llm)
    end

    def add_texts(texts: [])
      body = texts.map do |text|
        [
          { index: { _index: index_name } },
          { title: text, title_vector: llm.embed(text: text) }
        ]
      end.flatten

      es_client.bulk(body: body)
    end

    def update_texts(texts: [], ids: [])
      body = texts.map.with_index do |text, i|
        [
          { index: { _index: index_name, _id: ids[i] } },
          { title: text, title_vector: llm.embed(text: text) }
        ]
      end.flatten

      es_client.bulk(body: body)
    end

    def create_default_schema
      es_client.indices.create(
        index: index_name,
        body: default_schema
      )
    end

    def delete_default_schema
      es_client.indices.delete(
        index: index_name
      )
    end

    def default_schema
      {
        mappings: {
          properties: {
            title: {
              type: "text"
            },
            title_vector: {
              type: "dense_vector"
            }
          }
        }
      }
    end

    def cosine_similarity(text:, query_filter: {})
      query_vector = llm.embed(text: text)
      
      if query_filter.empty?
        query_filter = { match_all: {} }
      end

      es_client.search(
        query: {
          script_score: { query: query_filter },
          script: {
            source: "cosineSimilarity(params.query_vector, 'title_vector') + 1.0",
            params: { query_vector: query_vector }
          }
        }
      )
    end
  end
end

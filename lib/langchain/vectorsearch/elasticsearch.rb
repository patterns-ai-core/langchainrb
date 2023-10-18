# frozen_string_literal: true

module Langchain::Vectorsearch
  class Elasticsearch < Base
    #
    # Wrapper around Elasticsearch vector search capabilities.
    #
    # Setting up Elasticsearch:
    # 1. Get Elasticsearch up and running with Docker: https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
    # 2. Copy the HTTP CA certificate SHA-256 fingerprint and set the ELASTICSEARCH_CA_FINGERPRINT environment variable
    # 3. Set the ELASTICSEARCH_URL environment variable
    #
    # Gem requirements:
    #     gem "elasticsearch", "~> 8.0.0"
    #
    # Usage:
    #     llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
    #     es = Langchain::Vectorsearch::Elasticsearch.new(
    #       url: ENV["ELASTICSEARCH_URL"],
    #       index_name: "docs",
    #       llm: llm,
    #       es_options: {
    #         transport_options: {ssl: {verify: false}},
    #         ca_fingerprint: ENV["ELASTICSEARCH_CA_FINGERPRINT"]
    #       }
    #     )
    #
    #     es.create_default_schema
    #     es.add_texts(texts: ["..."])
    #     es.similarity_search(text: "...")
    #
    attr_accessor :es_client, :index_name, :options

    def initialize(url:, index_name:, llm:, api_key: nil, es_options: {})
      require "elasticsearch"

      @options = {
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
          {index: {_index: index_name}},
          {input: text, input_vector: llm.embed(text: text).embedding}
        ]
      end.flatten

      es_client.bulk(body: body)
    end

    def update_texts(texts: [], ids: [])
      body = texts.map.with_index do |text, i|
        [
          {index: {_index: index_name, _id: ids[i]}},
          {input: text, input_vector: llm.embed(text: text).embedding}
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

    def default_vector_settings
      {type: "dense_vector", dims: llm.default_dimension}
    end

    def vector_settings
      options[:vector_settings] || default_vector_settings
    end

    def default_schema
      {
        mappings: {
          properties: {
            input: {
              type: "text"
            },
            input_vector: vector_settings
          }
        }
      }
    end

    def default_query(query_vector)
      {
        script_score: {
          query: {match_all: {}},
          script: {
            source: "cosineSimilarity(params.query_vector, 'input_vector') + 1.0",
            params: {
              query_vector: query_vector
            }
          }
        }
      }
    end

    # TODO: Implement this
    # def ask()
    # end

    def similarity_search(text: "", k: 10, query: {})
      if text.empty? && query.empty?
        raise "Either text or query should pass as an argument"
      end

      if query.empty?
        query_vector = llm.embed(text: text).embedding

        query = default_query(query_vector)
      end

      es_client.search(body: {query: query, size: k}).body
    end

    def similarity_search_by_vector(embedding: [], k: 10, query: {})
      if embedding.empty? && query.empty?
        raise "Either embedding or query should pass as an argument"
      end

      query = default_query(embedding) if query.empty?

      es_client.search(body: {query: query, size: k}).body
    end
  end
end

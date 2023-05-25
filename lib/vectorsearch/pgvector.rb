# frozen_string_literal: true

module Vectorsearch
  class Pgvector < Base
    def initialize(url:, index_name:, llm:, llm_api_key:, api_key: nil)
      require "pg"
      require "pgvector"

      @client = ::PG.connect(url)
      registry = ::PG::BasicTypeRegistry.new.define_default_types
      ::Pgvector::PG.register_vector(registry)
      @client.type_map_for_results = PG::BasicTypeMapForResults.new(@client, registry: registry)

      @index_name = index_name

      super(llm: llm, llm_api_key: llm_api_key)
    end

    def add_texts(texts:)
      data = texts.flat_map do |text|
        [text, llm_client.embed(text: text)]
      end
      values = texts.length.times.map { |i| "($#{2 * i + 1}, $#{2 * i + 2})" }.join(",")
      client.exec_params(
        "INSERT INTO #{@index_name} (content, vectors) VALUES #{values};",
        data
      )
    end

    # Create default schema
    # @return [Hash] The response from the server
    def create_default_schema
      client.exec("CREATE EXTENSION IF NOT EXISTS vector;")
      client.exec(
        <<~SQL
          CREATE TABLE IF NOT EXISTS #{@index_name} (
            id serial PRIMARY KEY,
            content TEXT,
            vectors VECTOR(#{default_dimension})
          );
        SQL
      )
    end

    def similarity_search(query:, k: 4)
      embedding = llm_client.embed(text: query)

      similarity_search_by_vector(
        embedding: embedding,
        k: k
      )
    end

    def similarity_search_by_vector(embedding:, k: 4)
      result = client.transaction do |conn|
        conn.exec("SET LOCAL ivfflat.probes = 10;")
        query = <<~SQL
          SELECT id, content FROM #{@index_name} ORDER BY vectors <-> $1 ASC LIMIT $2;
        SQL
        conn.exec_params(query, [embedding, k])
      end

      result.to_a
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @return [String] The answer to the question
    def ask(question:)
      search_results = similarity_search(query: question)

      context = search_results.map do |result|
        result["content"].to_s
      end
      context = context.join("\n---\n")

      prompt = generate_prompt(question: question, context: context)

      llm_client.chat(prompt: prompt)
    end
  end
end

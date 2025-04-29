# frozen_string_literal: true

require "sqlite_vec"
module Langchain::Vectorsearch
  class SqliteVec < Base
    #
    # The SQLite vector search adapter using sqlite-vec
    #
    # Gem requirements:
    #     gem "sqlite3", "~> 2.5"
    #     gem "sqlite_vec", "~> 0.16.0"
    #
    # Usage:
    #     sqlite_vec = Langchain::Vectorsearch::SqliteVec.new(url:, index_name:, llm:, namespace: nil)
    #

    attr_reader :db, :table_name, :namespace_column, :namespace

    # @param url [String] The path to the SQLite database file (or :memory: for in-memory)
    # @param index_name [String] The name of the table to use for the index
    # @param llm [Object] The LLM client to use
    # @param namespace [String] The namespace to use for the index when inserting/querying
    def initialize(url:, index_name:, llm:, namespace: nil)
      depends_on "sqlite3"
      depends_on "sqlite_vec"

      @db = SQLite3::Database.new(url)
      @db.enable_load_extension(true)
      ::SqliteVec.load(@db)
      @db.enable_load_extension(false)

      @table_name = index_name
      @namespace_column = "namespace"
      @namespace = namespace

      super(llm: llm)
    end

    # Create default schema
    def create_default_schema
      @db.execute("CREATE VIRTUAL TABLE IF NOT EXISTS #{table_name} USING vec0(
        embedding float[#{llm.default_dimensions}],
        content TEXT,
        #{namespace_column} TEXT
      )")
    end

    # Destroy default schema
    def destroy_default_schema
      @db.execute("DROP TABLE IF EXISTS #{table_name}")
    end

    # Add a list of texts to the index
    # @param texts [Array<String>] The texts to add to the index
    # @param ids [Array<String>] The ids to add to the index, in the same order as the texts
    # @return [Array<Integer>] The ids of the added texts
    def add_texts(texts:, ids: nil)
      if ids.nil? || ids.empty?
        max_rowid = @db.execute("SELECT MAX(rowid) FROM #{table_name}").first.first || 0
        ids = texts.map.with_index do |_, i|
          max_rowid + i + 1
        end
      end

      @db.transaction do
        texts.zip(ids).each do |text, id|
          embedding = llm.embed(text: text).embedding
          @db.execute(
            "INSERT INTO #{table_name}(rowid, content, embedding, #{namespace_column}) VALUES (?, ?, ?, ?)",
            [id, text, embedding.pack("f*"), namespace]
          )
        end
      end

      ids
    end

    # Update a list of ids and corresponding texts in the index
    # @param texts [Array<String>] The texts to update in the index
    # @param ids [Array<String>] The ids to update in the index, in the same order as the texts
    # @return [Array<Integer>] The ids of the updated texts
    def update_texts(texts:, ids:)
      @db.transaction do
        texts.zip(ids).each do |text, id|
          embedding = llm.embed(text: text).embedding
          @db.execute(
            "UPDATE #{table_name} SET content = ?, embedding = ? WHERE rowid = ?",
            [text, embedding.pack("f*"), id]
          )
        end
      end
      ids
    end

    # Remove a list of texts from the index
    # @param ids [Array<Integer>] The ids of the texts to remove from the index
    # @return [Integer] The number of texts removed from the index
    def remove_texts(ids:)
      @db.execute("DELETE FROM #{table_name} WHERE rowid IN (#{ids.join(",")})")
      ids.length
    end

    # Search for similar texts in the index
    # @param query [String] The text to search for
    # @param k [Integer] The number of top results to return
    # @return [Array<Hash>] The results of the search
    def similarity_search(query:, k: 4)
      embedding = llm.embed(text: query).embedding
      similarity_search_by_vector(embedding: embedding, k: k)
    end

    # Search for similar texts in the index by vector
    # @param embedding [Array<Float>] The vector to search for
    # @param k [Integer] The number of top results to return
    # @return [Array<Hash>] The results of the search
    def similarity_search_by_vector(embedding:, k: 4)
      namespace_condition = namespace ? "AND #{namespace_column} = ?" : ""
      query_params = [embedding.pack("f*")]
      query_params << namespace if namespace

      @db.execute(<<-SQL, query_params)
        SELECT
          rowid,
          content,
          distance
        FROM #{table_name}
        WHERE embedding MATCH ?
        #{namespace_condition}
        ORDER BY distance
        LIMIT #{k}
      SQL
    end

    # Ask a question and return the answer
    # @param question [String] The question to ask
    # @param k [Integer] The number of results to have in context
    # @yield [String] Stream responses back one String at a time
    # @return [String] The answer to the question
    def ask(question:, k: 4, &)
      search_results = similarity_search(query: question, k: k)

      context = search_results.map { |result| result[1].to_s }
      context = context.join("\n---\n")

      prompt = generate_rag_prompt(question: question, context: context)

      messages = [{role: "user", content: prompt}]
      response = llm.chat(messages: messages, &)

      response.context = context
      response
    end
  end
end

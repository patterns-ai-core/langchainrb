# frozen_string_literal: true

module Langchain
  module Vectorsearch
    class Weaviate < Base
      # Initialize the Weaviate adapter
      # @param url [String] The URL of the Weaviate instance
      # @param api_key [String] The API key to use
      # @param index_name [String] The name of the index to use
      # @param llm [Symbol] The LLM to use
      # @param llm_api_key [String] The API key for the LLM
      def initialize(url:, api_key:, index_name:, llm:, llm_api_key:)
        depends_on "weaviate-ruby"
        require "weaviate"

        @client = ::Weaviate::Client.new(
          url: url,
          api_key: api_key,
          model_service: llm,
          model_service_api_key: llm_api_key
        )
        @index_name = index_name

        super(llm: llm, llm_api_key: llm_api_key)
      end

      # Add a list of texts to the index
      # @param texts [Array] The list of texts to add
      # @return [Hash] The response from the server
      def add_texts(texts:)
        objects = Array(texts).map do |text|
          {
            class: index_name,
            properties: {content: text}
          }
        end

        client.objects.batch_create(
          objects: objects
        )
      end

      # Create default schema
      def create_default_schema
        client.schema.create(
          class_name: index_name,
          vectorizer: "text2vec-#{llm}",
          # TODO: Figure out a way to optionally enable it
          # "module_config": {
          #   "qna-openai": {}
          # },
          properties: [
            # TODO: Allow passing in your own IDs
            {
              dataType: ["text"],
              name: "content"
            }
          ]
        )
      end

      # Return documents similar to the query
      # @param query [String] The query to search for
      # @param k [Integer|String] The number of results to return
      # @return [Hash] The search results
      def similarity_search(query:, k: 4)
        near_text = "{ concepts: [\"#{query}\"] }"

        client.query.get(
          class_name: index_name,
          near_text: near_text,
          limit: k.to_s,
          fields: "content _additional { id }"
        )
      end

      # Return documents similar to the vector
      # @param embedding [Array] The vector to search for
      # @param k [Integer|String] The number of results to return
      # @return [Hash] The search results
      def similarity_search_by_vector(embedding:, k: 4)
        near_vector = "{ vector: #{embedding} }"

        client.query.get(
          class_name: index_name,
          near_vector: near_vector,
          limit: k.to_s,
          fields: "content _additional { id }"
        )
      end

      # Ask a question and return the answer
      # @param question [String] The question to ask
      # @return [Hash] The answer
      def ask(question:)
        # Weaviate currently supports the `ask:` parameter only for the OpenAI LLM (with `qna-openai` module enabled).
        # The Cohere support is on the way: https://github.com/weaviate/weaviate/pull/2600
        if llm == :openai
          ask_object = "{ question: \"#{question}\" }"

          client.query.get(
            class_name: index_name,
            ask: ask_object,
            limit: "1",
            fields: "_additional { answer { result } }"
          )
        elsif llm == :cohere
          search_results = similarity_search(query: question)

          context = search_results.map do |result|
            result.dig("content").to_s
          end
          context = context.join("\n---\n")

          prompt = generate_prompt(question: question, context: context)

          llm_client.chat(prompt: prompt)
        end
      end
    end
  end
end

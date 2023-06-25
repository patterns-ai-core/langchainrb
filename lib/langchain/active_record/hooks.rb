# frozen_string_literal: true

module Langchain
  module ActiveRecord
    # This module adds the following functionality to your ActiveRecord models:
    # * `vectorsearch` class method to set the vector search provider
    # * `similarity_search` class method to search for similar texts
    # * `upsert_to_vectorsearch` instance method to upsert the record to the vector search provider
    #
    # Usage:
    #     class Recipe < ActiveRecord::Base
    #       vectorsearch provider: Langchain::Vectorsearch::Weaviate.new(
    #                    api_key: ENV["WEAVIATE_API_KEY"],
    #                    url: ENV["WEAVIATE_URL"],
    #                    index_name: "Recipes",
    #                    llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
    #                 )
    #
    #       after_save :upsert_to_vectorsearch
    #
    #       # Overwriting how the model is serialized before it's indexed
    #       def as_vector
    #         [
    #           "Title: #{title}",
    #           "Description: #{description}",
    #           ...
    #         ]
    #         .compact
    #         .join("\n")
    #       end
    #     end
    #
    # Create the default schema
    #     Recipe.class_variable_get(:@@provider).create_default_schema
    # Query the vector search provider
    #     Recipe.similarity_search("carnivore dish")
    # Delete the default schema to start over
    #     Recipe.class_variable_get(:@@provider).client.schema.delete class_name: "Recipes"
    #
    module Hooks
      def self.included(base)
        base.extend ClassMethods
      end

      # Index the text to the vector search provider
      # You'd typically call this method in an ActiveRecord callback
      #
      # @return [Boolean] true
      # @raise [Error] Indexing to vector search DB failed
      def upsert_to_vectorsearch
        if previously_new_record?
          self.class.class_variable_get(:@@provider).add_texts(
            texts: [as_vector],
            ids: [id]
          )
        else
          self.class.class_variable_get(:@@provider).update_texts(
            texts: [as_vector],
            ids: [id]
          )
        end
      end

      # Used to serialize the DB record to an indexable vector text
      # Overwrite this method in your model to customize
      #
      # @return [String] the text representation of the model
      def as_vector
        to_json
      end

      module ClassMethods
        # Set the vector search provider
        #
        # @param provider [Object] The `Langchain::Vectorsearch::*` instance
        def vectorsearch(provider:)
          class_variable_set(:@@provider, provider)
        end

        # Search for similar texts
        #
        # @param query [String] The query to search for
        # @param k [Integer] The number of results to return
        # @return [ActiveRecord::Relation] The ActiveRecord relation
        def similarity_search(query, k: 1)
          records = class_variable_get(:@@provider).similarity_search(
            query: query,
            k: k
          )
          ids = records.map { |record| record.dig("__id") }
          where(id: ids)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Langchain
  module ActiveRecord
    #
    # This module adds the following functionality to your ActiveRecord models:
    # * `vectorsearch` class method to set the provider
    # * `similarity_search` class method to search for similar texts
    # * `index_to_vectorsearch` instance method to index the text to the provider
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
    #       after_save :index_to_vectorsearch
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
      def index_to_vectorsearch
        self.class.class_variable_get(:@@provider).add_texts(texts: as_vector)

        true
      end

      # Used to serialize the DB record to an indexable vector text
      # Overwrite this method in your model to customize
      #
      # @return [String] the text representation of the model
      def as_vector
        to_json
      end

      module ClassMethods
        def vectorsearch(provider:)
          class_variable_set(:@@provider, provider)
        end

        def similarity_search(query, k: nil)
          class_variable_get(:@@provider).similarity_search(
            query: query,
            k: k
          )
        end
      end
    end
  end
end

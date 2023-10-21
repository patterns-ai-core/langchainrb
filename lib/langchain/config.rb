# frozen_string_literal: true

module Langchain
  class Config
    # Configuring the vectorsearch property to the used in the Rails apps
    #     Langchain.configure do |config|
    #       config.vectorsearch = Langchain::Vectorsearch::Weaviate.new(
    #         api_key: ENV["WEAVIATE_API_KEY"],
    #         url: ENV["WEAVIATE_URL"],
    #         index_name: "docs",
    #         llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
    #       )
    #     end
    attr_accessor :vectorsearch

    def initialize
      # Define the defaults for future configuration here
      @vectorsearch = {}
    end
  end
end


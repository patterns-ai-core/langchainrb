# frozen_string_literal: true

module Langchain
  class Config
    # This class is used to configure the Langchain.rb gem inside Rails apps, in the `config/initializers/langchain.rb` file.
    #
    # Langchain is configured in the following way:
    #     Langchain.configure do |config|
    #       config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
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

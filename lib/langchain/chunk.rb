# frozen_string_literal: true

module LangChain
  class Chunk
    # The chunking process is the process of splitting a document into smaller chunks and creating instances of LangChain::Chunk

    attr_reader :text

    # Initialize a new chunk
    # @param [String] text
    # @return [LangChain::Chunk]
    def initialize(text:)
      @text = text
    end
  end
end

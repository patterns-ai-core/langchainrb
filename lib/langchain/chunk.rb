# frozen_string_literal: true

module Langchain
  class Chunk
    # The chunking process is the process of splitting a document into smaller chunks and creating instances of Langchain::Chunk

    attr_reader :text

    # Initialize a new chunk
    # @param [String] text
    # @return [Langchain::Chunk]
    def initialize(text:)
      @text = text
    end
  end
end

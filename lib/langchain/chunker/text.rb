# frozen_string_literal: true

require "baran"

module Langchain
  module Chunker
    # Simple text chunker
    #
    # Splits the text on `separator`. A piece that is still longer than `chunk_size`
    # (for example a page without blank lines) is split further on newlines, then on spaces.
    #
    # Usage:
    #     Langchain::Chunker::Text.new(text).chunks
    class Text < Base
      attr_reader :text, :chunk_size, :chunk_overlap, :separator

      # @param [String] text
      # @param [Integer] chunk_size
      # @param [Integer] chunk_overlap
      # @param [String] separator
      def initialize(text, chunk_size: 1000, chunk_overlap: 200, separator: "\n\n")
        @text = text
        @chunk_size = chunk_size
        @chunk_overlap = chunk_overlap
        @separator = separator
      end

      # @return [Array<Langchain::Chunk>]
      def chunks
        splitter = Baran::RecursiveCharacterTextSplitter.new(
          chunk_size: chunk_size,
          chunk_overlap: chunk_overlap,
          separators: [separator, "\n", " "].uniq
        )

        splitter.chunks(text).map do |chunk|
          Langchain::Chunk.new(text: chunk[:text])
        end
      end
    end
  end
end

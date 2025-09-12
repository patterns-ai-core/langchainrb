# frozen_string_literal: true

require "baran"

module LangChain
  module Chunker
    # Simple text chunker
    #
    # Usage:
    #     LangChain::Chunker::Markdown.new(text).chunks
    class Markdown < Base
      attr_reader :text, :chunk_size, :chunk_overlap

      # @param [String] text
      # @param [Integer] chunk_size
      # @param [Integer] chunk_overlap
      # @param [String] separator
      def initialize(text, chunk_size: 1000, chunk_overlap: 200)
        @text = text
        @chunk_size = chunk_size
        @chunk_overlap = chunk_overlap
      end

      # @return [Array<LangChain::Chunk>]
      def chunks
        splitter = Baran::MarkdownSplitter.new(
          chunk_size: chunk_size,
          chunk_overlap: chunk_overlap
        )

        splitter.chunks(text).map do |chunk|
          LangChain::Chunk.new(text: chunk[:text])
        end
      end
    end
  end
end

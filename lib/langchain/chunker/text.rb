# frozen_string_literal: true

require "baran"

module Langchain
  module Chunker
    class Text < Base
      attr_reader :text, :chunk_size, :chunk_overlap, :separator

      def initialize(text, chunk_size: 1000, chunk_overlap: 200, separator: "\n\n")
        @text = text
        @chunk_size = chunk_size
        @chunk_overlap = chunk_overlap
        @separator = separator
      end

      def chunks
        splitter = Baran::CharacterTextSplitter.new(
          chunk_size: chunk_size,
          chunk_overlap: chunk_overlap,
          separator: separator
        )
        splitter.chunks(text)
      end
    end
  end
end

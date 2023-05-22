# frozen_string_literal: true

module Chunkers
  class Base
    attr_accessor :chunk_size, :chunk_overlap, :length

    LENGTH_FUNCTION = ->(text) { text.length }

    def initialize(chunk_size: 4000, chunk_overlap: 0, length: LENGTH_FUNCTION, **kwargs)
      raise ArgumentError, "Got a larger chunk overlap (#{chunk_overlap}) than chunk size (#{chunk_size}), should be smaller." if chunk_overlap >= chunk_size

      @chunk_size = chunk_size
      @chunk_overlap = chunk_overlap
      @length = length
    end

    def split_text(text)
      raise NotImplementedError
    end

    def chunked(text)
      split_text(text)
        .then { |a| split_into_chunks(a) }
        .then { |a| overlap_chunks(a) }
    end

    private

    def split_into_chunks(chunks)
      chunks
        .map { |chunk| chunk.scan(/.{1,#{chunk_size}}/) }
        .flatten
    end

    def overlap_chunks(chunks)
      return chunks if chunk_overlap.zero?

      # TODO - get this working
      # chunks
      #   ...
    end
  end
end

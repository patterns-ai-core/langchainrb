# frozen_string_literal: true

module Chunkers
  class Base
    attr_accessor :chunk_size, :chunk_overlap, :length

    LENGTH_FUNCTION = ->(text) { text.length }

    def initialize(chunk_size: 4000, chunk_overlap: 0, length: LENGTH_FUNCTION, **kwargs)
      raise ArgumentError, "Got a larger chunk overlap (#{chunk_overlap}) than chunk size (#{chunk_size}), should be smaller." if chunk_overlap > chunk_size

      @chunk_size = chunk_size
      @chunk_overlap = chunk_overlap
      @length = length
    end

    def split_text(text)
      raise NotImplementedError
    end
  end
end

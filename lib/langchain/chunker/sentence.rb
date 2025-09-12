# frozen_string_literal: true

require "pragmatic_segmenter"

module LangChain
  module Chunker
    # This chunker splits text by sentences.
    #
    # Usage:
    #     LangChain::Chunker::Sentence.new(text).chunks
    class Sentence < Base
      attr_reader :text

      # @param text [String]
      # @return [LangChain::Chunker::Sentence]
      def initialize(text)
        @text = text
      end

      # @return [Array<LangChain::Chunk>]
      def chunks
        ps = PragmaticSegmenter::Segmenter.new(text: text)
        ps.segment.map do |chunk|
          LangChain::Chunk.new(text: chunk)
        end
      end
    end
  end
end

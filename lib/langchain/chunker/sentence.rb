# frozen_string_literal: true

require "pragmatic_segmenter"

module Langchain
  module Chunker
    #
    # This chunker splits text by sentences.
    #
    # Usage:
    #     Langchain::Chunker::Sentence.new(text).chunks
    #
    class Sentence < Base
      attr_reader :text

      # @param text [String]
      # @return [Langchain::Chunker::Sentence]
      def initialize(text)
        @text = text
      end

      # @return [Array<String>]
      def chunks
        ps = PragmaticSegmenter::Segmenter.new(text: text)
        ps.segment
      end
    end
  end
end

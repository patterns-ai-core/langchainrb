# frozen_string_literal: true

module LangChain
  module Chunker
    # = Chunkers
    # Chunkers are used to split documents into smaller chunks before indexing into vector search databases.
    # Otherwise large documents, when retrieved and passed to LLMs, may hit the context window limits.
    #
    # == Available chunkers
    #
    # - {LangChain::Chunker::RecursiveText}
    # - {LangChain::Chunker::Text}
    # - {LangChain::Chunker::Semantic}
    # - {LangChain::Chunker::Sentence}
    class Base
      # @return [Array<LangChain::Chunk>]
      def chunks
        raise NotImplementedError
      end
    end
  end
end

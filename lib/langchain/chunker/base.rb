# frozen_string_literal: true

module Langchain
  module Chunker
    # = Chunkers
    # Chunkers are used to split documents into smaller chunks before indexing into vector search databases.
    # Otherwise large documents, when retrieved and passed to LLMs, may hit the context window limits.
    #
    # == Available chunkers
    #
    # - {Langchain::Chunker::RecursiveText}
    # - {Langchain::Chunker::Text}
    # - {Langchain::Chunker::Semantic}
    # - {Langchain::Chunker::Sentence}
    class Base
      # @return [Array<Langchain::Chunk>]
      def chunks
        raise NotImplementedError
      end
    end
  end
end

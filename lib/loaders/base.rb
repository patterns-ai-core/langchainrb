# frozen_string_literal: true

# TODO: Add chunking options to the loaders

module Loaders
  class Base
    def self.load(path)
      new.load(path)
    end

    def initialize(path, chunker: nil, **kwargs)
      @path = path
      @chunker = setup_chunker(chunker)
    end

    def loadable?
      raise NotImplementedError
    end

    attr_reader :path, :chunker

    def path_extension
      path.extname
    end

    private

    def setup_chunker(chunker)
      chunker_klass = chunker || Langchain.default_chunker || Chunkers::TextSplitter

      # chunker_klass can be a Chunker class or an instance of a Chunker class.
      # make sure it's an instance of a Chunker class.
      chunker_klass = chunker_klass.new if chunker_klass.is_a?(Class)

      raise ArgumentError, "Chunker must be a Chunker class or instance" unless chunker_klass.is_a?(Chunkers::Base)

      chunker_klass
    end
  end
end

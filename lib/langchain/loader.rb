# frozen_string_literal: true

require "open-uri"

module Langchain
  class Loader
    class FileNotFound < StandardError; end

    class UnknownFormatError < StandardError; end

    URI_REGEX = %r{\A[A-Za-z][A-Za-z0-9+\-.]*://}

    # Load data from a file or url
    # Equivalent to Langchain::Loader.new(path).load
    # @param path [String | Pathname] path to file or url
    # @return [String] file content
    def self.load(path)
      new(path).load
    end

    # Initialize Langchain::Loader
    # @param path [String | Pathname] path to file or url
    # @return [Langchain::Loader] loader instance
    def initialize(path)
      @path = path
    end

    # Check if path is url
    # @return [Boolean] true if path is url
    def url?
      return false if @path.is_a?(Pathname)

      !!(@path =~ URI_REGEX)
    end

    # Load data from a file or url
    # @return [String] file content
    def load
      url? ? from_url(@path) : from_path(@path)
    end

    private

    def from_url(url)
      process do
        data = URI.parse(url).open
        processor = find_processor(:CONTENT_TYPES, data.content_type)
        [data, processor]
      end
    end

    def from_path(path)
      raise FileNotFound unless File.exist?(path)

      process do
        [File.open(path), find_processor(:EXTENSIONS, File.extname(path))]
      end
    end

    def process(&block)
      raw_data, kind = yield

      raise UnknownFormatError unless kind

      processor = Langchain::Processors.const_get(kind).new
      Langchain::Data.new(processor.parse(raw_data), source: @path)
    end

    def find_processor(constant, value)
      processors.find { |klass| processor_matches? "#{klass}::#{constant}", value }
    end

    def processor_matches?(constant, value)
      Langchain::Processors.const_get(constant).include?(value)
    end

    def processors
      Langchain::Processors.constants
    end
  end
end

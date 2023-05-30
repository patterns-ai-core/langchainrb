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
    def self.load(path, options = {}, &block)
      new(path, options).load(&block)
    end

    # Initialize Langchain::Loader
    # @param path [String | Pathname] path to file or url
    # @return [Langchain::Loader] loader instance
    def initialize(path, options = {})
      @options = options
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
    def load(&block)
      @raw_data = url? ? load_from_url : load_from_path

      data = if block
        yield @raw_data.read, @options
      else
        processor_klass.new(@options).parse(@raw_data)
      end

      Langchain::Data.new(data, source: @path)
    end

    private

    def load_from_url
      URI.parse(@path).open
    end

    def load_from_path
      raise FileNotFound unless File.exist?(@path)

      File.open(@path)
    end

    def processor_klass
      raise UnknownFormatError unless (kind = find_processor)

      Langchain::Processors.const_get(kind)
    end

    def find_processor
      processors.find { |klass| processor_matches? "#{klass}::#{lookup_constant}", source_type }
    end

    def processor_matches?(constant, value)
      Langchain::Processors.const_get(constant).include?(value)
    end

    def processors
      Langchain::Processors.constants
    end

    def source_type
      url? ? @raw_data.content_type : File.extname(@path)
    end

    def lookup_constant
      url? ? :CONTENT_TYPES : :EXTENSIONS
    end
  end
end

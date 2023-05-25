# frozen_string_literal: true

require "open-uri"

module Langchain
  class Loader
    class FileNotFound < StandardError; end

    class UnknownFormatError < StandardError; end

    URI_REGEX = %r{\A[A-Za-z][A-Za-z0-9+\-.]*://}

    def self.load(path)
      new(path).load
    end

    def initialize(path)
      @path = path
    end

    def url?
      return false if @path.is_a?(Pathname)

      !!(@path =~ URI_REGEX)
    end

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
      data, processor = yield

      raise UnknownFormatError unless processor

      Langchain::Processors.const_get(processor).new.parse(data)
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

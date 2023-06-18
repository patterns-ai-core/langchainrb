# frozen_string_literal: true

module Langchain
  class Data
    attr_reader :source

    def initialize(data, options = {})
      @source = options[:source]
      @data = data
    end

    def value
      @data
    end

    def chunks(opts = {})
      Langchain::Chunker::Text.new(@data, **opts).chunks
    end
  end
end

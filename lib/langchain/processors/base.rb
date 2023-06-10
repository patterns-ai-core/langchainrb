# frozen_string_literal: true

module Langchain
  module Processors
    # Processors load and parse/process various data types such as CSVs, PDFs, Word documents, HTML pages, and others.
    class Base
      include Langchain::DependencyHelper

      EXTENSIONS = []
      CONTENT_TYPES = []

      def initialize(options = {})
        @options = options
      end

      def parse(data)
        raise NotImplementedError
      end
    end
  end
end

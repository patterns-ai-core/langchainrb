# frozen_string_literal: true

module Langchain
  module Processors
    class PDF < Base
      EXTENSIONS = [".pdf"]
      CONTENT_TYPES = ["application/pdf"]

      def initialize(*)
        depends_on "pdf-reader"
      end

      # Parse the document and return the text
      # @param [File] data
      # @return [String]
      def parse(data)
        ::PDF::Reader
          .new(StringIO.new(data.read))
          .pages
          .map(&:text)
          .join("\n\n")
      end
    end
  end
end

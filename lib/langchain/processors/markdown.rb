# frozen_string_literal: true

module Langchain
  module Processors
    class Markdown < Base
      EXTENSIONS = [".markdown", ".md"]
      CONTENT_TYPES = ["text/markdown"]

      # Parse the document and return the text
      # @param [File] data
      # @return [String]
      def parse(data)
        data.read
      end
    end
  end
end

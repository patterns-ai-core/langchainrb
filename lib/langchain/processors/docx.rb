# frozen_string_literal: true

module Langchain
  module Processors
    class Docx < Base
      EXTENSIONS = [".docx"]
      CONTENT_TYPES = ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"]

      def initialize(*)
        depends_on "docx"
      end

      # Parse the document and return the text
      # @param [File] data
      # @return [String]
      def parse(data)
        ::Docx::Document
          .open(StringIO.new(data.read))
          .text
      end
    end
  end
end

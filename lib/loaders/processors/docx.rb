# frozen_string_literal: true

module Loaders
  module Processors
    class Docx < Base
      EXTENSIONS = ['.docx']
      CONTENT_TYPES = ['application/vnd.openxmlformats-officedocument.wordprocessingml.document']

      def initialize
        depends_on "docx"
        require "docx"
      end

      def parse(data)
        ::Docx::Document
          .open(StringIO.new(data.read))
          .text
      end
    end
  end
end


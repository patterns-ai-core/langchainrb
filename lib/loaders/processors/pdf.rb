# frozen_string_literal: true

module Loaders
  module Processors
    class PDF
      EXTENSIONS = [".pdf"]
      CONTENT_TYPES = ["application/pdf"]

      def initialize
        depends_on "pdf-reader"
        require "pdf-reader"
      end

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

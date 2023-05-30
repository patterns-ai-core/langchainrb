# frozen_string_literal: true

require "csv"

module Langchain
  module Processors
    class CSV < Base
      EXTENSIONS = [".csv"]
      CONTENT_TYPES = ["text/csv"]

      # Parse the document and return the text
      # @param [File] data
      # @return [Array of Hash]
      def parse(data)
        ::CSV.new(data.read, col_sep: separator).map do |row|
          row.map(&:strip)
        end
      end

      private

      def separator
        @options[:col_sep] || ","
      end
    end
  end
end

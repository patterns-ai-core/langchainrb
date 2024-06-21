# frozen_string_literal: true

require "csv"

module Langchain
  module Processors
    class CSV < Base
      class InvalidChunkMode < StandardError; end

      EXTENSIONS = [".csv"]
      CONTENT_TYPES = ["text/csv"]
      CHUNK_MODE = {
        row: "row",
        file: "file"
      }

      # Parse the document and return the text
      # @param [File] data
      # @return [String]
      def parse(data)
        case chunk_mode
        when CHUNK_MODE[:row]
          chunk_row(data)
        when CHUNK_MODE[:file]
          chunk_file(data)
        else
          raise InvalidChunkMode
        end
      end

      private

      def separator
        @options[:col_sep] || ","
      end

      def chunk_mode
        if @options[:chunk_mode].to_s.empty?
          CHUNK_MODE[:row]
        else
          raise InvalidChunkMode unless CHUNK_MODE.value?(@options[:chunk_mode])

          @options[:chunk_mode]
        end
      end

      def chunk_row(data)
        ::CSV.new(data.read, col_sep: separator).map do |row|
          row
            .compact
            .map(&:strip)
            .join(separator)
        end.join("\n\n")
      end

      def chunk_file(data)
        data.read
      end
    end
  end
end

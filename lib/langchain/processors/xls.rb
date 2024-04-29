# frozen_string_literal: true

module Langchain
  module Processors
    class Xls < Base
      EXTENSIONS = [".xls"].freeze
      CONTENT_TYPES = ["application/vnd.ms-excel"].freeze

      def initialize(*)
        depends_on "roo"
        depends_on "roo-xls"
      end

      # Parse the document and return the text
      # @param [File] data
      # @return [Array<Array<String>>] Array of rows, each row is an array of cells
      def parse(data)
        xls_file = Roo::Spreadsheet.open(data)
        xls_file.each_with_pagename.flat_map do |_, sheet|
          sheet.map do |row|
            row.map { |i| i.to_s.strip }
          end
        end
      end
    end
  end
end

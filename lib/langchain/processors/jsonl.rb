# frozen_string_literal: true

module Langchain
  module Processors
    class JSONL < Base
      EXTENSIONS = [".jsonl"]
      CONTENT_TYPES = ["application/jsonl", "application/json-lines", "application/jsonlines"]

      # Parse the document and return the text
      # @param [File] data
      # @return [Array of Hash]
      def parse(data)
        data.read.each_line.filter_map do |line|
          line.strip!
          ::JSON.parse(line) unless line.empty?
        end
      end
    end
  end
end

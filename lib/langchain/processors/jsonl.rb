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
        data.read.lines.map do |line|
          ::JSON.parse(line)
        end
      end
    end
  end
end

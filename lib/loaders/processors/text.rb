# frozen_string_literal: true

module Loaders
  module Processors
    class Text
      EXTENSIONS = [".txt"]
      CONTENT_TYPES = ["text/plain"]

      def parse(data)
        data.read
      end
    end
  end
end

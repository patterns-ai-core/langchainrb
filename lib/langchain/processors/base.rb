# frozen_string_literal: true

module Langchain
  module Processors
    class Base
      EXTENSIONS = []
      CONTENT_TYPES = []

      def initialize(options = {})
        @options = options
      end

      def parse(data)
        raise NotImplementedError
      end
    end
  end
end

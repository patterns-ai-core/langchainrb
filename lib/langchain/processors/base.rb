# frozen_string_literal: true

module Langchain
  module Processors
    class Base
      EXTENSIONS = []
      CONTENT_TYPES = []

      def parse(data)
        raise NotImplementedError
      end
    end
  end
end

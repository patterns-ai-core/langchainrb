# frozen_string_literal: true

module Loaders
  class Docx < Base
    #
    # This Loader parses Docx files into text.
    # If you'd like to use it directly you can do so like this:
    # Loaders::Docx.new("path/to/my.docx").load
    #
    # This parser is also invoked when you're adding data to a Vectorsearch DB:
    # qdrant = Vectorsearch::Qdrant.new(...)
    # path = Langchain.root.join("path/to/my.docx")
    # qdrant.add_data(path: path)
    #

    def initialize(path)
      depends_on "docx"
      require "docx"

      @path = path
    end

    # Check that the file is a `.docx` file
    def loadable?
      @path.to_s.end_with?(".docx")
    end

    def load
      ::Docx::Document
        .open(@path.to_s)
        .text
    end
  end
end

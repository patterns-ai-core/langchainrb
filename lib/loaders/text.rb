module Loaders
  class Text < Base
    #
    # This Loader parses .txt files.
    # If you'd like to use it directly you can do so like this:
    # Loaders::Text.new("path/to/my.txt").load
    #
    # This parser is also invoked when you're adding data to a Vectorsearch DB:
    # qdrant = Vectorsearch::Qdrant.new(...)
    # path = Langchain.root.join("path/to/my.txt")
    # qdrant.add_data(path: path)
    #

    def loadable?
      @path.to_s.end_with?(".txt")
    end

    def load
      @path.read
    end
  end
end

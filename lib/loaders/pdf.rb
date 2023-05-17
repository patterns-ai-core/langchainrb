module Loaders
  class PDF < Base
    def initialize(path)
      depends_on "pdf-reader"
      require "pdf-reader"

      @path = path
    end

    def loadable?
      @path.to_s.end_with?(".pdf")
    end

    def load
      ::PDF::Reader
        .new(@path)
        .pages
        .map(&:text)
        .join("\n\n")
    end
  end
end

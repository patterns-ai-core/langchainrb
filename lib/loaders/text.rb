module Loaders
  class Text < Base
    def loadable?
      true
    end

    def load
      @path.read
    end
  end
end

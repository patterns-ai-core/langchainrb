# frozen_string_literal: true

# TODO: Add chunking options to the loaders

module Loaders
  class Base
    def self.load(path)
      new.load(path)
    end

    def initialize(path)
      @path = path
    end

    def loadable?
      raise NotImplementedError
    end
  end
end

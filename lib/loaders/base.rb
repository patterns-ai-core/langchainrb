# frozen_string_literal: true

module Loaders
  class Base
    def self.load(path)
      new.load(path)
    end

    def initialize(path)
      @path = path
    end

    def loadable?
      raise "Not implemented"
    end
  end
end

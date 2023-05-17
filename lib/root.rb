# frozen_string_literal: true

module Langchain
  def self.root
    @@root ||= Pathname.new(__dir__)
  end
end

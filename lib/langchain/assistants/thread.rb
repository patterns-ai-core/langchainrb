# frozen_string_literal: true

module Langchain
  class Thread
    attr_accessor :messages

    def initialize(messages: [])
      @messages = messages
    end
  end
end

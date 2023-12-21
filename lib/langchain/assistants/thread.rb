# frozen_string_literal: true

module Langchain
  class Thread
    attr_accessor :messages

    # @param messages [Array<Langchain::Message>]
    def initialize(messages: [])
      raise ArgumentError, "messages array must only contain Langchain::Message instance(s)" unless messages.is_a?(Array) && messages.all? { |m| m.is_a?(Langchain::Message) }

      @messages = messages
    end
  end
end

# frozen_string_literal: true

module Langchain
  class Conversation
    class Response < Message
      def type
        "ai"
      end
    end
  end
end

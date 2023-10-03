# frozen_string_literal: true

module Langchain
  class Conversation
    class Context < Message
      def type
        "system"
      end
    end
  end
end

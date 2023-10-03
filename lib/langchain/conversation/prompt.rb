# frozen_string_literal: true

module Langchain
  class Conversation
    class Prompt < Message
      def type
        "human"
      end
    end
  end
end

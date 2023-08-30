# frozen_string_literal: true

module Langchain
  class AIMessage < Message
    def type
      "ai"
    end
  end
end

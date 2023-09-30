# frozen_string_literal: true

module Langchain
  class HumanMessage < Message
    def type
      "human"
    end
  end
end

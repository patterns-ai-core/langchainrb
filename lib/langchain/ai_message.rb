# frozen_string_literal: true

module Langchain
  class AIMessage < Message
    def self.from_llm_response(llm_response, completion_path)
      return new(llm_response) if completion_path.nil?

      completion = llm_response.dig(*completion_path)
      content = completion["content"]
      extra = completion.except("content")
      new(content, extra)
    end

    def type
      "ai"
    end
  end
end

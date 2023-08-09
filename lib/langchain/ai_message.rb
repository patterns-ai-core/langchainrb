# frozen_string_literal: true

module Langchain
  class AIMessage < Message
    def self.from_llm_response(llm_klass, llm_response)
      data = llm_response.clone
      content = data.delete(CONTENT_MAPPING[llm_klass])
      new(content, data)
    end

    def type
      "ai"
    end
  end
end

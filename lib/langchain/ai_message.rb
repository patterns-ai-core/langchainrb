# frozen_string_literal: true

module Langchain
  class AIMessage < Message
    def self.from_llm_response(llm_klass, llm_response)
      case llm_klass
      when Langchain::LLM::Cohere
        new(llm_response)
      when Langchain::LLM::GooglePalm
        new(llm_response.dig("candidates", 0, "content"))
      when Langchain::LLM::OpenAI
        message = llm_response.dig("choices", 0, "message") || llm_response.dig("choices", 0, "delta")
        new(message["content"], message.except("content"))
      when Langchain::LLM::Replicate
        new(llm_response)
      end
    end

    def type
      "ai"
    end
  end
end

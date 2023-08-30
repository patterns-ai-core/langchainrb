module Langchain
  module LLM
    class OpenAIChatParser
      def content(llm_response)
        message(llm_response)["content"]
      end

      def additional_kwargs(llm_response)
        message(llm_response).except("content", "role")
      end

      private

      def message(llm_response)
        choice = llm_response.dig("choices", 0)
        choice["message"] || choice["delta"]
      end
    end
  end
end

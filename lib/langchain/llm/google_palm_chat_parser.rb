module Langchain
  module LLM
    class GooglePalmChatParser
      def content(llm_response)
        message(llm_response)["content"]
      end

      def additional_kwargs(llm_response)
        message(llm_response).except("content", "role")
      end

      private

      def message(llm_response)
        llm_response.dig("candidates", 0)
      end
    end
  end
end

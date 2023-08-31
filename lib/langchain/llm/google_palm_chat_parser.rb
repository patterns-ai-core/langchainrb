module Langchain
  module LLM
    class GooglePalmChatParser
      ROLE_MAPPING = {
        "human" => "user"
      }

      def content(llm_response)
        message(llm_response)["content"]
      end

      def additional_kwargs(llm_response)
        message(llm_response).except("content", "role")
      end

      def to_llm(author, content, additional_kwargs = {})
        {author: ROLE_MAPPING.fetch(author, author), content: content, **Hash(additional_kwargs)}
      end

      private

      def message(llm_response)
        llm_response.dig("candidates", 0)
      end
    end
  end
end

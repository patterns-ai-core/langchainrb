module Langchain
  module LLM
    class OpenAIChatParser
      ROLE_MAPPING = {
        "ai" => "assistant",
        "human" => "user"
      }

      def content(llm_response)
        message(llm_response)["content"]
      end

      def additional_kwargs(llm_response)
        message(llm_response).except("content", "role")
      end

      def to_llm(role, content, additional_kwargs = {})
        {role: ROLE_MAPPING.fetch(role, role), content: content, **Hash(additional_kwargs)}
      end

      private

      def message(llm_response)
        choice = llm_response.dig("choices", 0)
        choice["message"] || choice["delta"]
      end
    end
  end
end

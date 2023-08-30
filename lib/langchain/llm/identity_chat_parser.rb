module Langchain
  module LLM
    class IdentityChatParser
      ROLE_MAPPING = {
        "ai" => "assistant",
        "human" => "user"
      }

      def content(llm_response)
        llm_response
      end

      def additional_kwargs(_llm_response)
        {}
      end

      def to_llm(role, content, additional_kwargs = {})
        { role: ROLE_MAPPING.fetch(role, role), content: content, **additional_kwargs }
      end
    end
  end
end

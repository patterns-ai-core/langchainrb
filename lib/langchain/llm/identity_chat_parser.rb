module Langchain
  module LLM
    class IdentityChatParser
      def content(llm_response)
        llm_response
      end

      def additional_kwargs(_llm_response)
        {}
      end
    end
  end
end

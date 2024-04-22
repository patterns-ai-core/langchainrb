# frozen_string_literal: true

module Langchain
  module Messages
    # Langchain::Message are the messages that are sent to LLM chat methods
    class Base
      attr_reader :role, :content, :tool_calls, :tool_call_id

      def user?
        role == "user"
      end
    end
  end
end

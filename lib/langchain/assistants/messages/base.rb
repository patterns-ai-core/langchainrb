# frozen_string_literal: true

module Langchain
  module Messages
    class Base
      attr_reader :role, :content, :tool_calls, :tool_call_id

      # Check if the message came from a user
      #
      # @param [Boolean] true/false whether the message came from a user
      def user?
        role == "user"
      end
    end
  end
end

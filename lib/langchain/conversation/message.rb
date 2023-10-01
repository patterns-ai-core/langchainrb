# frozen_string_literal: true

module Langchain
  class Conversation
    class Message
      attr_reader :content

      ROLE_MAPPING = {
        context: "system",
        prompt: "user",
        response: "assistant"
      }

      def initialize(content)
        @content = content
      end

      def role
        ROLE_MAPPING[type]
      end

      def to_s
        content
      end

      def to_h
        {
          role: role,
          content: content
        }
      end

      def ==(other)
        to_json == other.to_json
      end

      def to_json(options = {})
        to_h.to_json
      end

      private

      def type
        self.class.to_s.split("::").last.downcase.to_sym
      end
    end
  end
end

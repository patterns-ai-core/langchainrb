# frozen_string_literal: true

module Langchain
  class Conversation
    class Message
      attr_reader :content, :additional_kwargs

      ROLE_MAPPING = {
        context: "system",
        prompt: "user",
        response: "assistant"
      }

      def initialize(content, additional_kwargs = nil)
        @content = content
        @additional_kwargs = additional_kwargs
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
        hash = to_h

        hash[:additional_kwargs] = additional_kwargs unless additional_kwargs.nil? || additional_kwargs.empty?

        hash.to_json
      end

      private

      def type
        self.class.to_s.split("::").last.downcase.to_sym
      end
    end
  end
end

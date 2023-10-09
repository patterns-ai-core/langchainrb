# frozen_string_literal: true

module Langchain
  module LLM
    class BaseResponse
      attr_reader :raw_response

      def initialize(raw_response, **options)
        @raw_response = raw_response
        @options = options
      end

      def model
        raise NotImplementedError
      end

      def type
        raise NotImplementedError
      end

      def completions
        raise NotImplementedError
      end

      def embeddings
        raise NotImplementedError
      end

      def value
        raise NotImplementedError
      end

      def prompt_tokens
        raise NotImplementedError
      end

      def completion_tokens
        raise NotImplementedError
      end

      def total_tokens
        raise NotImplementedError
      end

      protected

      attr_reader :options
    end
  end
end

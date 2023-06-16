# frozen_string_literal: true

module Langchain
  module Utils
    module TokenLength
      class TokenLimitExceeded < StandardError
        attr_reader :token_overflow

        def initialize(message = "", token_overflow = 0)
          super message

          @token_overflow = token_overflow
        end
      end
    end
  end
end

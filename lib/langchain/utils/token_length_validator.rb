# frozen_string_literal: true

require "tiktoken_ruby"

module Langchain
  module Utils
    class TokenLimitExceeded < StandardError; end

    class TokenLengthValidator
      TOKEN_LIMITS = {
        "text-embedding-ada-002" => 8191, # Source: https://platform.openai.com/docs/api-reference/embeddings
        "text-davinci-003" => 4097, # Source: https://platform.openai.com/docs/models/gpt-3-5
        "gpt-3.5-turbo" => 4096, # Source: https://platform.openai.com/docs/models/gpt-3-5
        "gpt-4" => 8192 # Source: https://platform.openai.com/docs/models/gpt-4
      }.freeze

      def self.validate!(text, model_name)
        encoder = Tiktoken.encoding_for_model(model_name)
        token_length = encoder.encode(text).length

        if token_length > TOKEN_LIMITS[model_name]
          raise TokenLimitExceeded, "This model's maximum context length is #{TOKEN_LIMITS[model_name]} tokens, but the given text is #{token_length} tokens long."
        end
      end
    end
  end
end

# frozen_string_literal: true

require "tiktoken_ruby"

module Langchain
  module Utils
    class TokenLimitExceeded < StandardError; end

    class TokenLengthValidator
      #
      # This class is meant to validate the length of the text passed in to OpenAI's API.
      # It is used to validate the token length before the API call is made
      #
      TOKEN_LIMITS = {
        # Source:
        # https://platform.openai.com/docs/api-reference/embeddings
        # https://platform.openai.com/docs/models/gpt-4
        "text-embedding-ada-002" => 8191,
        "gpt-3.5-turbo" => 4096,
        "gpt-3.5-turbo-0301" => 4096,
        "text-davinci-003" => 4097,
        "text-davinci-002" => 4097,
        "code-davinci-002" => 8001,
        "gpt-4" => 8192,
        "gpt-4-0314" => 8192,
        "gpt-4-32k" => 32768,
        "gpt-4-32k-0314" => 32768,
        "text-curie-001" => 2049,
        "text-babbage-001" => 2049,
        "text-ada-001" => 2049,
        "davinci" => 2049,
        "curie" => 2049,
        "babbage" => 2049,
        "ada" => 2049
      }.freeze

      #
      # Validate the length of the text passed in to OpenAI's API
      #
      # @param text [String] The text to validate
      # @param model_name [String] The model name to validate against
      # @return [Boolean] Whether the text is valid or not
      # @raise [TokenLimitExceeded] If the text is too long
      #
      def self.validate!(text, model_name)
        encoder = Tiktoken.encoding_for_model(model_name)
        token_length = encoder.encode(text).length

        if token_length > TOKEN_LIMITS[model_name]
          raise TokenLimitExceeded, "This model's maximum context length is #{TOKEN_LIMITS[model_name]} tokens, but the given text is #{token_length} tokens long."
        end

        true
      end
    end
  end
end

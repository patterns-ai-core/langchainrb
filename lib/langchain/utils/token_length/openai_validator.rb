# frozen_string_literal: true

require "tiktoken_ruby"

module Langchain
  module Utils
    module TokenLength
      #
      # This class is meant to validate the length of the text passed in to OpenAI's API.
      # It is used to validate the token length before the API call is made
      #
      class OpenAIValidator < BaseValidator
        TOKEN_LIMITS = {
          # Source:
          # https://platform.openai.com/docs/api-reference/embeddings
          # https://platform.openai.com/docs/models/gpt-4
          "text-embedding-ada-002" => 8191,
          "gpt-3.5-turbo" => 4096,
          "gpt-3.5-turbo-0301" => 4096,
          "gpt-3.5-turbo-0613" => 4096,
          "gpt-3.5-turbo-16k" => 16384,
          "gpt-3.5-turbo-16k-0613" => 16384,
          "text-davinci-003" => 4097,
          "text-davinci-002" => 4097,
          "code-davinci-002" => 8001,
          "gpt-4" => 8192,
          "gpt-4-0314" => 8192,
          "gpt-4-0613" => 8192,
          "gpt-4-32k" => 32768,
          "gpt-4-32k-0314" => 32768,
          "gpt-4-32k-0613" => 32768,
          "gpt-4-1106-preview" => 128000,
          "gpt-4-vision-preview" => 128000,
          "text-curie-001" => 2049,
          "text-babbage-001" => 2049,
          "text-ada-001" => 2049,
          "davinci" => 2049,
          "curie" => 2049,
          "babbage" => 2049,
          "ada" => 2049
        }.freeze

        #
        # Calculate token length for a given text and model name
        #
        # @param text [String] The text to calculate the token length for
        # @param model_name [String] The model name to validate against
        # @return [Integer] The token length of the text
        #
        def self.token_length(text, model_name, options = {})
          encoder = Tiktoken.encoding_for_model(model_name)
          encoder.encode(text).length
        end

        def self.token_limit(model_name)
          TOKEN_LIMITS[model_name]
        end
      end
    end
  end
end

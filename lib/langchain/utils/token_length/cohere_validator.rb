# frozen_string_literal: true

module Langchain
  module Utils
    module TokenLength
      #
      # This class is meant to validate the length of the text passed in to Cohere's API.
      # It is used to validate the token length before the API call is made
      #

      class CohereValidator
        TOKEN_LIMITS = {
          # Source:
          # https://docs.cohere.com/docs/models
          "command-light" => 4096,
          "command" => 4096,
          "base-light" => 2048,
          "base" => 2048,
          "embed-english-light-v2.0" => 512,
          "embed-english-v2.0" => 512,
          "embed-multilingual-v2.0" => 256,
          "summarize-medium" => 2048,
          "summarize-xlarge" => 2048
        }.freeze
        #
        # Calculate the `max_tokens:` parameter to be set by calculating the context length of the text minus the prompt length
        #
        # @param content [String | Array<String>] The text or array of texts to validate
        # @param model_name [String] The model name to validate against
        # @return [Integer] Whether the text is valid or not
        # @raise [TokenLimitExceeded] If the text is too long
        #
        def self.validate_max_tokens!(content, model_name, client)
          text_token_length = if content.is_a?(Array)
            content.sum { |item| token_length(item.to_json, model_name, client) }
          else
            token_length(content, model_name, client)
          end

          max_tokens = TOKEN_LIMITS[model_name] - text_token_length

          # Raise an error even if whole prompt is equal to the model's token limit (max_tokens == 0) since not response will be returned
          if max_tokens <= 0
            raise TokenLimitExceeded, "This model's maximum context length is #{TOKEN_LIMITS[model_name]} tokens, but the given text is #{text_token_length} tokens long."
          end

          max_tokens
        end

        #
        # Calculate token length for a given text and model name
        #
        # @param text [String] The text to calculate the token length for
        # @param model_name [String] The model name to validate against
        # @return [Integer] The token length of the text
        #
        def self.token_length(text, model_name, client)
          res = client.tokenize(text: text)
          res["tokens"].length
        end
      end
    end
  end
end

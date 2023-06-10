# frozen_string_literal: true

require "tiktoken_ruby"

module Langchain
  module Utils
    module TokenLength
      class TokenLimitExceeded < StandardError; end

      #
      # This class is meant to validate the length of the text passed in to Google Palm's API.
      # It is used to validate the token length before the API call is made
      #
      class GooglePalmValidator
        TOKEN_LIMITS = {
          # Source:
          # This data can be pulled when `list_models()` method is called: https://github.com/andreibondarev/google_palm_api#usage

          # chat-bison-001 is the only model that currently supports countMessageTokens functions
          "chat-bison-001" => {
            "input_token_limit" => 4000, # 4096 is the limit the the countMessageTokens does not return anything higher than 4000
            "output_token_limit" => 1024
          }
          # "text-bison-001" => {
          #   "input_token_limit" => 8196,
          #   "output_token_limit" => 1024
          # },
          # "embedding-gecko-001" => {
          #   "input_token_limit" => 1024
          # }
        }.freeze

        #
        # Calculate the `max_tokens:` parameter to be set by calculating the context length of the text minus the prompt length
        #
        # @param content [String | Array<String>] The text or array of texts to validate
        # @param model_name [String] The model name to validate against
        # @return [Integer] Whether the text is valid or not
        # @raise [TokenLimitExceeded] If the text is too long
        #
        def self.validate_max_tokens!(google_palm_llm, content, model_name)
          text_token_length = if content.is_a?(Array)
            content.sum { |item| token_length(google_palm_llm, item.to_json, model_name) }
          else
            token_length(google_palm_llm, content, model_name)
          end

          leftover_tokens = TOKEN_LIMITS.dig(model_name, "input_token_limit") - text_token_length

          # Raise an error even if whole prompt is equal to the model's token limit (max_tokens == 0) since not response will be returned
          if leftover_tokens <= 0
            raise TokenLimitExceeded, "This model's maximum context length is #{TOKEN_LIMITS.dig(model_name, "input_token_limit")} tokens, but the given text is #{text_token_length} tokens long."
          end

          leftover_tokens
        end

        #
        # Calculate token length for a given text and model name
        #
        # @param llm [Langchain::LLM:GooglePalm] The Langchain::LLM:GooglePalm instance
        # @param text [String] The text to calculate the token length for
        # @param model_name [String] The model name to validate against
        # @return [Integer] The token length of the text
        #
        def self.token_length(llm, text, model_name = "chat-bison-001")
          response = llm.client.count_message_tokens(model: model_name, prompt: text)
          response.dig("tokenCount")
        end
      end
    end
  end
end

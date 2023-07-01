# frozen_string_literal: true

module Langchain
  module Utils
    module TokenLength
      #
      # This class is meant to validate the length of the text passed in to Google Palm's API.
      # It is used to validate the token length before the API call is made
      #
      class GooglePalmValidator < BaseValidator
        TOKEN_LIMITS = {
          # Source:
          # This data can be pulled when `list_models()` method is called: https://github.com/andreibondarev/google_palm_api#usage

          # chat-bison-001 is the only model that currently supports countMessageTokens functions
          "chat-bison-001" => {
            "input_token_limit" => 4000, # 4096 is the limit but the countMessageTokens does not return anything higher than 4000
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
        # Calculate token length for a given text and model name
        #
        # @param text [String] The text to calculate the token length for
        # @param model_name [String] The model name to validate against
        # @param options [Hash] the options to create a message with
        # @option options [Langchain::LLM:GooglePalm] :llm The Langchain::LLM:GooglePalm instance
        # @return [Integer] The token length of the text
        #
        def self.token_length(text, model_name = "chat-bison-001", options)
          response = options[:llm].client.count_message_tokens(model: model_name, prompt: text)

          raise Langchain::LLM::ApiError.new(response["error"]["message"]) unless response["error"].nil?

          response.dig("tokenCount")
        end

        def self.token_limit(model_name)
          TOKEN_LIMITS.dig(model_name, "input_token_limit")
        end
      end
    end
  end
end

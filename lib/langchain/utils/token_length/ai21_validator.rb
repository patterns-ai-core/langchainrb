# frozen_string_literal: true

module Langchain
  module Utils
    module TokenLength
      #
      # This class is meant to validate the length of the text passed in to AI21's API.
      # It is used to validate the token length before the API call is made
      #

      class AI21Validator < BaseValidator
        TOKEN_LIMITS = {
          "j2-ultra" => 8192,
          "j2-mid" => 8192,
          "j2-light" => 8192
        }.freeze

        #
        # Calculate token length for a given text and model name
        #
        # @param text [String] The text to calculate the token length for
        # @param model_name [String] The model name to validate against
        # @return [Integer] The token length of the text
        #
        def self.token_length(text, model_name, client)
          res = client.tokenize(text)
          res.dig(:tokens).length
        end

        def self.token_limit(model_name)
          TOKEN_LIMITS[model_name]
        end
        singleton_class.alias_method :completion_token_limit, :token_limit
      end
    end
  end
end

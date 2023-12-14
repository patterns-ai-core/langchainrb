# frozen_string_literal: true

module Langchain
  module Utils
    module TokenLength
      #
      # Calculate the `max_tokens:` parameter to be set by calculating the context length of the text minus the prompt length
      #
      # @param content [String | Array<String>] The text or array of texts to validate
      # @param model_name [String] The model name to validate against
      # @return [Integer] Whether the text is valid or not
      # @raise [TokenLimitExceeded] If the text is too long
      #
      class BaseValidator
        def self.validate_max_tokens!(content, model_name, options = {})
          text_token_length = if content.is_a?(Array)
            token_length_from_messages(content, model_name, options)
          else
            token_length(content, model_name, options)
          end

          leftover_tokens = token_limit(model_name) - text_token_length

          # Some models have a separate token limit for completions (e.g. GPT-4 Turbo)
          # We want the lower of the two limits
          max_tokens = [leftover_tokens, completion_token_limit(model_name)].min

          # Raise an error even if whole prompt is equal to the model's token limit (leftover_tokens == 0)
          if max_tokens < 0
            raise limit_exceeded_exception(token_limit(model_name), text_token_length)
          end

          max_tokens
        end

        def self.limit_exceeded_exception(limit, length)
          TokenLimitExceeded.new("This model's maximum context length is #{limit} tokens, but the given text is #{length} tokens long.", length - limit)
        end
      end
    end
  end
end

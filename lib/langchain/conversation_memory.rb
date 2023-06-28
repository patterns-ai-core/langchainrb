# frozen_string_literal: true

module Langchain
  class ConversationMemory
    attr_reader :context, :examples, :messages

    # The least number of tokens we want to be under the limit by
    TOKEN_LEEWAY = 20

    def initialize(llm:, messages: [], **options)
      @llm = llm
      @context = nil
      @examples = []
      @messages = messages
      @options = options
    end

    def set_context(message)
      @context = message
    end

    def add_examples(examples)
      @examples.concat examples
    end

    def append_ai_message(message)
      @messages << {role: "ai", content: message}
    end

    def append_user_message(message)
      @messages << {role: "user", content: message}
    end

    def reduce_messages(exception)
      raise exception if @messages.size == 1

      token_overflow = exception.token_overflow

      @messages = @messages.drop_while do |message|
        proceed = token_overflow > -TOKEN_LEEWAY
        token_overflow -= token_length(message.to_json, model_name, llm: @llm)

        proceed
      end
    end

    private

    def model_name
      @options[:model] || @llm.class::DEFAULTS[:chat_completion_model_name]
    end

    def token_length(content, model_name, options)
      @llm.class::LENGTH_VALIDATOR.token_length(content, model_name, options)
    end
  end
end

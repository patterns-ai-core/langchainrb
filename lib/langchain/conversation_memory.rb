# frozen_string_literal: true

module Langchain
  class ConversationMemory
    attr_reader :llm, :examples, :messages

    attr_accessor :functions

    # The least number of tokens we want to be under the limit by
    TOKEN_LEEWAY = 20

    def initialize(llm:, messages: [], functions: [], **options)
      @llm = llm
      @context = nil
      @summary = nil
      @examples = []
      @messages = messages

      @functions = functions
      validate_functions_parameter!

      @strategy = options.delete(:strategy) || :truncate
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
      case @strategy
      when :truncate
        truncate_messages(exception)
      when :summarize
        summarize_messages
      else
        raise "Unknown strategy: #{@options[:strategy]}"
      end
    end

    def context
      return if @context.nil? && @summary.nil?

      [@context, @summary].compact.join("\n")
    end

    private

    def validate_functions_parameter!
      if functions.any? && !llm.is_a?(Langchain::LLM::OpenAI)
        raise ArgumentError, "Functions are currently only supported by Langchain::LLM::OpenAI"
      end
    end

    def truncate_messages(exception)
      raise exception if @messages.size == 1

      token_overflow = exception.token_overflow

      @messages = @messages.drop_while do |message|
        proceed = token_overflow > -TOKEN_LEEWAY
        token_overflow -= token_length(message.to_json, model_name, llm: llm)

        proceed
      end
    end

    def summarize_messages
      history = [@summary, @messages.to_json].compact.join("\n")
      partitions = [history[0, history.size / 2], history[history.size / 2, history.size]]

      @summary = partitions.map { |messages| llm.summarize(text: messages.to_json) }.join("\n")

      @messages = [@messages.last]
    end

    def partition_messages
    end

    def model_name
      llm.class::DEFAULTS[:chat_completion_model_name]
    end

    def token_length(content, model_name, options)
      llm.class::LENGTH_VALIDATOR.token_length(content, model_name, options)
    end
  end
end

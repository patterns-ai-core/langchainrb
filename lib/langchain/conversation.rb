# frozen_string_literal: true

module Langchain
  #
  # A high-level API for running a conversation with an LLM.
  # Currently supports: OpenAI and Google PaLM LLMs.
  #
  # Usage:
  #     llm = Langchain::LLM::OpenAI.new(api_key: "YOUR_API_KEY")
  #     chat = Langchain::Conversation.new(llm: llm)
  #     chat.set_context("You are a chatbot from the future")
  #     chat.message("Tell me about future technologies")
  #
  # To stream the chat response:
  #     chat = Langchain::Conversation.new(llm: llm) do |chunk|
  #       print(chunk)
  #     end
  #
  class Conversation
    attr_reader :context, :examples, :messages

    # The least number of tokens we want to be under the limit by
    TOKEN_LEEWAY = 20

    # Intialize Conversation with a LLM
    #
    # @param llm [Object] The LLM to use for the conversation
    # @param options [Hash] Options to pass to the LLM, like temperature, top_k, etc.
    # @return [Langchain::Conversation] The Langchain::Conversation instance
    def initialize(llm:, **options, &block)
      @llm = llm
      @context = nil
      @examples = []
      @messages = options.delete(:messages) || []
      @options = options
      @block = block
    end

    # Set the context of the conversation. Usually used to set the model's persona.
    # @param message [String] The context of the conversation
    def set_context(message)
      @context = message
    end

    # Add examples to the conversation. Used to give the model a sense of the conversation.
    # @param examples [Array<Hash>] The examples to add to the conversation
    def add_examples(examples)
      @examples.concat examples
    end

    # Message the model with a prompt and return the response.
    # @param message [String] The prompt to message the model with
    # @return [String] The response from the model
    def message(message)
      append_user_message(message)
      response = llm_response(message)
      append_ai_message(response)
      response
    end

    private

    def llm_response(prompt)
      begin
        @llm.chat(messages: @messages, context: @context, examples: @examples, **@options, &@block)
      rescue Langchain::Utils::TokenLength::TokenLimitExceeded => exception
        raise exception if @messages.size == 1

        reduce_messages(exception.token_overflow)
        retry
      end
    end

    def reduce_messages(token_overflow)
      @messages = @messages.drop_while do |message|
        proceed = token_overflow > -TOKEN_LEEWAY
        token_overflow -= Langchain::Utils::TokenLength::OpenAIValidator.token_length(message[:content], model_name)

        proceed
      end
    end

    def append_ai_message(message)
      @messages << {role: "ai", content: message}
    end

    def append_user_message(message)
      @messages << {role: "user", content: message}
    end

    def model_name
      @options[:model] || @llm.class::DEFAULTS[:chat_completion_model_name]
    end
  end
end

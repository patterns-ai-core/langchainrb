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
    attr_reader :options

    # Intialize Conversation with a LLM
    #
    # @param llm [Object] The LLM to use for the conversation
    # @param options [Hash] Options to pass to the LLM, like temperature, top_k, etc.
    # @return [Langchain::Conversation] The Langchain::Conversation instance
    def initialize(llm:, **options, &block)
      @llm = llm
      @context = nil
      @examples = []
      @memory = ConversationMemory.new(
        llm: llm,
        messages: options.delete(:messages) || [],
        strategy: options.delete(:memory_strategy)
      )
      @options = options
      @block = block
    end

    def set_functions(functions)
      @llm.functions = functions
    end

    # Set the context of the conversation. Usually used to set the model's persona.
    # @param message [String] The context of the conversation
    def set_context(message)
      @memory.set_context SystemMessage.new(message)
    end

    # Add examples to the conversation. Used to give the model a sense of the conversation.
    # @param examples [Array<AIMessage|HumanMessage>] The examples to add to the conversation
    def add_examples(examples)
      @memory.add_examples examples
    end

    # Message the model with a prompt and return the response.
    # @param message [String] The prompt to message the model with
    # @return [AIMessage] The response from the model
    def message(message)
      human_message = HumanMessage.new(message)
      @memory.append_message(human_message)
      llm_response = call_llm
      ai_message = AIMessage.new(
        @llm.chat_parser.content(llm_response),
        @llm.chat_parser.additional_kwargs(llm_response)
      )
      @memory.append_message(ai_message)
      ai_message
    end

    # Messages from conversation memory
    # @return [Array<AIMessage|HumanMessage>] The messages from the conversation memory
    def messages
      @memory.messages
    end

    # Context from conversation memory
    # @return [SystemMessage] Context from conversation memory
    def context
      @memory.context
    end

    # Examples from conversation memory
    # @return [Array<AIMessage|HumanMessage>] Examples from the conversation memory
    def examples
      @memory.examples
    end

    private

    def call_llm
      @llm.chat(messages: messages, context: context&.to_s, examples: examples, **@options, &@block)
    rescue Langchain::Utils::TokenLength::TokenLimitExceeded => exception
      @memory.reduce_messages(exception)
      retry
    end
  end
end

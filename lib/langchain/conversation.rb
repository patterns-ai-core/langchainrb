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
      @memory = ::Langchain::Conversation::Memory.new(
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
      @memory.set_context ::Langchain::Conversation::Context.new(message)
    end

    # Add examples to the conversation. Used to give the model a sense of the conversation.
    # @param examples [Array<Prompt|Response>] The examples to add to the conversation
    def add_examples(examples)
      @memory.add_examples examples
    end

    # Message the model with a prompt and return the response.
    # @param message [String] The prompt to message the model with
    # @return [Response] The response from the model
    def message(message)
      @memory.append_message ::Langchain::Conversation::Prompt.new(message)
      ai_message = ::Langchain::Conversation::Response.new(llm_response.chat_completion)
      @memory.append_message(ai_message)
      ai_message
    end

    # Messages from conversation memory
    # @return [Array<Prompt|Response>] The messages from the conversation memory
    def messages
      @memory.messages
    end

    # Context from conversation memory
    # @return [Context] Context from conversation memory
    def context
      @memory.context
    end

    # Examples from conversation memory
    # @return [Array<Prompt|Response>] Examples from the conversation memory
    def examples
      @memory.examples
    end

    private

    def llm_response
      @llm.chat(messages: @memory.messages.map(&:to_h), context: @memory.context&.to_s, examples: @memory.examples.map(&:to_h), **@options, &@block)
    rescue Langchain::Utils::TokenLength::TokenLimitExceeded => exception
      @memory.reduce_messages(exception)
      retry
    end
  end
end

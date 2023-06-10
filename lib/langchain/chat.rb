# frozen_string_literal: true

module Langchain
  class Chat
    attr_reader :context

    def initialize(llm:, **options)
      @llm = llm
      @context = nil
      @examples = []
      @messages = []
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
      @llm.chat(messages: @messages, context: @context, examples: @examples)
    end

    def append_ai_message(message)
      @messages << {role: "ai", content: message}
    end

    def append_user_message(message)
      @messages << {role: "user", content: message}
    end
  end
end

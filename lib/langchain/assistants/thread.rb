# frozen_string_literal: true

module Langchain
  # Langchain::Thread keeps track of messages in a conversation.
  # TODO: Add functionality to persist to the thread to disk, DB, storage, etc.
  class Thread
    attr_accessor :messages, :add_message_callback

    # @param messages [Array<Langchain::Message>]
    # @param add_message_callback [Proc] A callback to call when a message is added to the thread
    def initialize(messages: [], add_message_callback: nil)
      raise ArgumentError, "messages array must only contain Langchain::Message instance(s)" unless messages.is_a?(Array) && messages.all? { |m| m.is_a?(Langchain::Messages::Base) }

      @add_message_callback = add_message_callback
      @messages = messages
    end

    # Convert the thread to an LLM APIs-compatible array of hashes
    #
    # @return [Array<Hash>] The thread as an OpenAI API-compatible array of hashes
    def array_of_message_hashes
      messages
        .map(&:to_hash)
        .compact
    end

    # Only used by the Assistant when it calls the LLM#complete() method
    def prompt_of_concatenated_messages
      messages.map(&:to_s).join
    end

    # Add a message to the thread
    #
    # @param message [Langchain::Message] The message to add
    # @return [Array<Langchain::Message>] The updated messages array
    def add_message(message)
      raise ArgumentError, "message must be a Langchain::Message instance" unless message.is_a?(Langchain::Messages::Base)

      # Call the callback with the message
      add_message_callback.call(message) if add_message_callback # rubocop:disable Style/SafeNavigation

      # Prepend the message to the thread
      messages << message
    end
  end
end

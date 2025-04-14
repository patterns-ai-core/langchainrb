# frozen_string_literal: true

module Langchain
  class Assistant
    module Messages
      class Base
        attr_reader :role,
          :content,
          :image_url,
          :tool_calls,
          :tool_call_id

        # Check if the message came from a user
        #
        # @return [Boolean] true/false whether the message came from a user
        def user?
          role == "user"
        end

        # Check if the message came from an LLM
        #
        # @raise NotImplementedError if the subclass does not implement this method
        def llm?
          raise NotImplementedError, "Class #{self.class.name} must implement the method 'llm?'"
        end

        # Check if the message is a tool call
        #
        # @raise NotImplementedError if the subclass does not implement this method
        def tool?
          raise NotImplementedError, "Class #{self.class.name} must implement the method 'tool?'"
        end

        # Check if the message is a system prompt
        #
        # @raise NotImplementedError if the subclass does not implement this method
        def system?
          raise NotImplementedError, "Class #{self.class.name} must implement the method 'system?'"
        end

        # Returns the standardized role symbol based on the specific role methods
        #
        # @return [Symbol] the standardized role symbol (:system, :llm, :tool, :user, or :unknown)
        def standard_role
          return :user if user?
          return :llm if llm?
          return :tool if tool?
          return :system if system?

          # TODO: Should we return :unknown or raise an error?
          :unknown
        end

        def image
          image_url ? Utils::ImageWrapper.new(image_url) : nil
        end
      end
    end
  end
end

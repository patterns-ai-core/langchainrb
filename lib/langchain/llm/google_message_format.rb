# frozen_string_literal: true

module Langchain::LLM
  # Lets Google Gemini and Vertex AI take messages in the `{role:, content:}` shape the rest of the
  # library sends (`Vectorsearch#ask`, `OutputFixingParser`, the Ragas evals...). The API only accepts
  # `{role:, parts: [...]}`, with "model" for the assistant and the system prompt outside `contents`.
  module GoogleMessageFormat
    private

    # @param params [Hash] The #chat params
    # @return [Hash] The params with text messages converted, and system messages moved to :system
    def to_google_messages(params)
      messages = Array(params[:messages])
      system_texts, messages = messages.partition { |message| role_of(message) == "system" && text_content?(message) }
      system_texts = system_texts.map { |message| content_of(message) }
      system_texts.unshift(params[:system]) if params[:system]

      params.merge(
        messages: messages.map { |message| text_content?(message) ? text_message(message) : message },
        system: system_texts.any? ? system_texts.join("\n\n") : nil
      ).compact
    end

    def text_message(message)
      role = (role_of(message) == "assistant") ? "model" : role_of(message)
      {role: role, parts: [{text: content_of(message)}]}
    end

    # Only a String content is converted: messages already in Google's shape have :parts instead
    def text_content?(message)
      message.is_a?(Hash) && content_of(message).is_a?(String) && !(message.key?(:parts) || message.key?("parts"))
    end

    def role_of(message)
      (message[:role] || message["role"]).to_s
    end

    def content_of(message)
      message.key?(:content) ? message[:content] : message["content"]
    end
  end
end

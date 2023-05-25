# frozen_string_literal: true

module LLM
  class GooglePalm < Base
    # Wrapper around the Google PaLM (Pathways Language Model) APIs.

    DEFAULTS = {
      temperature: 0.0,
      dimension: 768 # This is what the `embedding-gecko-001` model generates
    }.freeze

    def initialize(api_key:)
      depends_on "google_palm_api"
      require "google_palm_api"

      @client = ::GooglePalmApi::Client.new(api_key: api_key)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Array] The embedding
    #
    def embed(text:)
      response = client.embed(
        text: text
      )
      response.dig("embedding", "value")
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @return [String] The completion
    #
    def complete(prompt:, **params)
      default_params = {
        prompt: prompt,
        temperature: DEFAULTS[:temperature]
      }

      if params[:stop_sequences]
        default_params[:stop_sequences] = params.delete(:stop_sequences)
      end

      if params[:max_tokens]
        default_params[:max_output_tokens] = params.delete(:max_tokens)
      end

      default_params.merge!(params)

      response = client.generate_text(**default_params)
      response.dig("candidates", 0, "output")
    end

    #
    # Generate a chat completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @return [String] The chat completion
    #
    def chat(prompt:, **params)
      # TODO: Figure out how to introduce persisted conversations
      default_params = {
        prompt: prompt,
        temperature: DEFAULTS[:temperature]
      }

      if params[:stop_sequences]
        default_params[:stop] = params.delete(:stop_sequences)
      end

      if params[:max_tokens]
        default_params[:max_output_tokens] = params.delete(:max_tokens)
      end

      default_params.merge!(params)

      response = client.generate_chat_message(**default_params)
      response.dig("candidates", 0, "content")
    end
  end
end

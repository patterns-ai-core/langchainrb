# frozen_string_literal: true

module LLM
  class OpenAI < Base
    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "text-davinci-003",
      embeddings_model_name: "text-embedding-ada-002",
      dimension: 1536
    }.freeze

    def initialize(api_key:)
      depends_on "ruby-openai"
      require "openai"

      # TODO: Add support to pass `organization_id:`
      @client = ::OpenAI::Client.new(access_token: api_key)
    end

    # Generate an embedding for a given text
    # @param text [String] The text to generate an embedding for
    # @return [Array] The embedding
    def embed(text:)
      response = client.embeddings(
        parameters: {
          model: DEFAULTS[:embeddings_model_name],
          input: text
        }
      )
      response.dig("data").first.dig("embedding")
    end

    # Generate a completion for a given prompt
    # @param prompt [String] The prompt to generate a completion for
    # @return [String] The completion
    def complete(prompt:, **params)
      default_params = {
        model: DEFAULTS[:completion_model_name],
        temperature: DEFAULTS[:temperature],
        prompt: prompt
      }

      if params[:stop_sequences]
        default_params[:stop] = params.delete(:stop_sequences)
      end

      default_params.merge!(params)

      response = client.completions(parameters: default_params)
      response.dig("choices", 0, "text")
    end

    alias_method :generate_completion, :complete
    alias_method :generate_embedding, :embed
  end
end

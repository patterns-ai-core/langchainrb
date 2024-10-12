# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around AI21 Studio APIs.
  #
  # Gem requirements:
  #   gem "ai21", "~> 0.2.1"
  #
  # Usage:
  #     llm = Langchain::LLM::AI21.new(api_key: ENV["AI21_API_KEY"])
  #
  class AI21 < Base
    DEFAULTS = {
      temperature: 0.0,
      model: "j2-ultra"
    }.freeze

    def initialize(api_key:, default_options: {})
      depends_on "ai21"

      @client = ::AI21::Client.new(api_key)
      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params [Hash] The parameters to pass to the API
    # @return [Langchain::LLM::AI21Response] The completion
    #
    def complete(prompt:, **params)
      parameters = complete_parameters params

      response = client.complete(prompt, parameters)
      Langchain::LLM::AI21Response.new response, model: parameters[:model]
    end

    #
    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @param params [Hash] The parameters to pass to the API
    # @return [String] The summary
    #
    def summarize(text:, **params)
      response = client.summarize(text, "TEXT", params)
      response.dig(:summary)
      # Should we update this to also return a Langchain::LLM::AI21Response?
    end

    private

    def complete_parameters(params)
      @defaults.dup.merge(params)
    end
  end
end

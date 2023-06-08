# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around AI21 Studio APIs.
  #
  # Gem requirements:
  #   gem "ai21", "~> 0.2.0"
  #
  # Usage:
  #     ai21 = Langchain::LLM::AI21.new(api_key:)
  #
  class AI21 < Base
    def initialize(api_key:)
      depends_on "ai21"
      require "ai21"

      @client = ::AI21::Client.new(api_key)
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params [Hash] The parameters to pass to the API
    # @return [String] The completion
    #
    def complete(prompt:, **params)
      response = client.complete(prompt, params)
      response.dig(:completions, 0, :data, :text)
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
    end
  end
end

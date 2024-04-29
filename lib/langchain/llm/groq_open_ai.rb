# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Groq OpenAI compatible services
  #
  # Usage:
  #    groq = Langchain::LLM::GroqOpenAi.new(
  #      api_key: ENV["GROQ_API_KEY"],
  #      llm_options: {},
  #      default_options: {}
  #    )
  class GroqOpenAi < OpenAI
    DEFAULTS_GROQ = {
      uri_base: "https://api.groq.com/openai/",
      chat_completion_model_name: "llama3-8b-8192"
    }.freeze

    def initialize(api_key:, llm_options: {}, default_options: {})
      llm_options[:uri_base] = DEFAULTS_GROQ[:uri_base] unless llm_options[:uri_base]
      default_options[:chat_completion_model_name] = DEFAULTS_GROQ[:chat_completion_model_name] unless default_options[:chat_completion_model_name]

      super
    end
  end
end

module Langchain::LLM
  # LLM interface for Groq OpenAI compatible services
  #
  # Usage:
  #    groq = Langchain::LLM::GroqOpenAI.new(
  #      api_key: ENV["GROQ_API_KEY"],
  #      llm_options: {},
  #      default_options: {}
  #    )
  class Groq < OpenAI
    DEFAULTS_GROQ = {
      chat_completion_model_name: "llama3-8b-8192"
    }.freeze

    def initialize(api_key:, llm_options: {}, default_options: {})
      llm_options[:uri_base] = "https://api.groq.com/openai/"
      default_options[:chat_completion_model_name] = DEFAULTS_GROQ[:chat_completion_model_name] unless default_options[:chat_completion_model_name]

      super
    end
  end
end

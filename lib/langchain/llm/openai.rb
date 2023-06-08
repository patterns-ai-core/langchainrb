# frozen_string_literal: true

module Langchain::LLM
  class OpenAI < Base
    #
    # Wrapper around OpenAI APIs.
    #
    # Gem requirements: gem "ruby-openai", "~> 4.0.0"
    #
    # Usage:
    # openai = Langchain::LLM::OpenAI.new(api_key:, llm_options: {})
    #

    DEFAULTS = {
      temperature: 0.0,
      completion_model_name: "text-davinci-003",
      chat_completion_model_name: "gpt-3.5-turbo",
      embeddings_model_name: "text-embedding-ada-002",
      dimension: 1536
    }.freeze

    def initialize(api_key:, llm_options: {})
      depends_on "ruby-openai"
      require "openai"

      @client = ::OpenAI::Client.new(access_token: api_key, **llm_options)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Array] The embedding
    #
    def embed(text:, **params)
      parameters = {model: DEFAULTS[:embeddings_model_name], input: text}

      Langchain::Utils::TokenLengthValidator.validate_max_tokens!(text, parameters[:model])

      response = client.embeddings(parameters: parameters.merge(params))
      response.dig("data").first.dig("embedding")
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @return [String] The completion
    #
    def complete(prompt:, **params)
      parameters = compose_parameters DEFAULTS[:completion_model_name], params

      parameters[:prompt] = prompt
      parameters[:max_tokens] = Langchain::Utils::TokenLengthValidator.validate_max_tokens!(prompt, parameters[:model])

      response = client.completions(parameters: parameters)
      response.dig("choices", 0, "text")
    end

    #
    # Generate a chat completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @return [String] The chat completion
    #
    def chat(prompt:, **params)
      parameters = compose_parameters DEFAULTS[:chat_completion_model_name], params

      parameters[:messages] = [{role: "user", content: prompt}]
      parameters[:max_tokens] = Langchain::Utils::TokenLengthValidator.validate_max_tokens!(prompt, parameters[:model])

      response = client.chat(parameters: parameters)
      response.dig("choices", 0, "message", "content")
    end

    #
    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    #
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.json")
      )
      prompt = prompt_template.format(text: text)

      complete(prompt: prompt, temperature: DEFAULTS[:temperature])
    end

    private

    def compose_parameters(model, params)
      default_params = {model: model, temperature: DEFAULTS[:temperature]}

      default_params[:stop] = params.delete(:stop_sequences) if params[:stop_sequences]

      default_params.merge(params)
    end
  end
end

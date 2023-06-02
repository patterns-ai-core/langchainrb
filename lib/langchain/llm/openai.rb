# frozen_string_literal: true

module Langchain::LLM
  class OpenAI < Base
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
    def embed(text:)
      model = DEFAULTS[:embeddings_model_name]

      Langchain::Utils::TokenLengthValidator.validate!(text, model)

      response = client.embeddings(
        parameters: {
          model: model,
          input: text
        }
      )
      response.dig("data").first.dig("embedding")
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @return [String] The completion
    #
    def complete(prompt:, **params)
      model = DEFAULTS[:completion_model_name]

      Langchain::Utils::TokenLengthValidator.validate!(prompt, model)

      default_params = {
        model: model,
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

    #
    # Generate a chat completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @return [String] The chat completion
    #
    def chat(prompt:, **params)
      model = DEFAULTS[:chat_completion_model_name]

      Langchain::Utils::TokenLengthValidator.validate!(prompt, model)

      default_params = {
        model: model,
        temperature: DEFAULTS[:temperature],
        # TODO: Figure out how to introduce persisted conversations
        messages: [{role: "user", content: prompt}]
      }

      if params[:stop_sequences]
        default_params[:stop] = params.delete(:stop_sequences)
      end

      default_params.merge!(params)

      response = client.chat(parameters: default_params)
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

      complete(
        prompt: prompt,
        temperature: DEFAULTS[:temperature],
        # Most models have a context length of 2048 tokens (except for the newest models, which support 4096).
        max_tokens: 2048
      )
    end
  end
end

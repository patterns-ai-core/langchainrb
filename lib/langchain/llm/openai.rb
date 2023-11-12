# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for OpenAI APIs: https://platform.openai.com/overview
  #
  # Gem requirements:
  #    gem "ruby-openai", "~> 5.2.0"
  #
  # Usage:
  #    openai = Langchain::LLM::OpenAI.new(api_key:, llm_options: {})
  #
  class OpenAI < Base
    DEFAULTS = {
      n: 1,
      temperature: 0.0,
      completion_model_name: "gpt-3.5-turbo",
      chat_completion_model_name: "gpt-3.5-turbo",
      embeddings_model_name: "text-embedding-ada-002",
      dimension: 1536
    }.freeze

    LEGACY_COMPLETION_MODELS = %w[
      ada
      babbage
      curie
      davinci
    ].freeze

    LENGTH_VALIDATOR = Langchain::Utils::TokenLength::OpenAIValidator

    attr_accessor :functions

    def initialize(api_key:, llm_options: {}, default_options: {})
      depends_on "ruby-openai", req: "openai"

      @client = ::OpenAI::Client.new(access_token: api_key, **llm_options)
      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param params extra parameters passed to OpenAI::Client#embeddings
    # @return [Langchain::LLM::OpenAIResponse] Response object
    #
    def embed(text:, **params)
      parameters = {model: @defaults[:embeddings_model_name], input: text}

      validate_max_tokens(text, parameters[:model])

      response = with_api_error_handling do
        client.embeddings(parameters: parameters.merge(params))
      end

      Langchain::LLM::OpenAIResponse.new(response)
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params  extra parameters passed to OpenAI::Client#complete
    # @return [Langchain::LLM::Response::OpenaAI] Response object
    #
    def complete(prompt:, **params)
      parameters = compose_parameters @defaults[:completion_model_name], params

      return legacy_complete(prompt, parameters) if is_legacy_model?(parameters[:model])

      parameters[:messages] = compose_chat_messages(prompt: prompt)
      parameters[:max_tokens] = validate_max_tokens(parameters[:messages], parameters[:model], parameters[:max_tokens])

      response = with_api_error_handling do
        client.chat(parameters: parameters)
      end

      Langchain::LLM::OpenAIResponse.new(response)
    end

    #
    # Generate a chat completion for a given prompt or messages.
    #
    # == Examples
    #
    #     # simplest case, just give a prompt
    #     openai.chat prompt: "When was Ruby first released?"
    #
    #     # prompt plus some context about how to respond
    #     openai.chat context: "You are RubyGPT, a helpful chat bot for helping people learn Ruby", prompt: "Does Ruby have a REPL like IPython?"
    #
    #     # full control over messages that get sent, equivilent to the above
    #     openai.chat messages: [
    #       {
    #         role: "system",
    #         content: "You are RubyGPT, a helpful chat bot for helping people learn Ruby", prompt: "Does Ruby have a REPL like IPython?"
    #       },
    #       {
    #         role: "user",
    #         content: "When was Ruby first released?"
    #       }
    #     ]
    #
    #     # few-short prompting with examples
    #     openai.chat prompt: "When was factory_bot released?",
    #       examples: [
    #         {
    #           role: "user",
    #           content: "When was Ruby on Rails released?"
    #         }
    #         {
    #           role: "assistant",
    #           content: "2004"
    #         },
    #       ]
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @param messages [Array<Hash>] The messages that have been sent in the conversation
    # @param context [String] An initial context to provide as a system message, ie "You are RubyGPT, a helpful chat bot for helping people learn Ruby"
    # @param examples [Array<Hash>] Examples of messages to provide to the model. Useful for Few-Shot Prompting
    # @param options [Hash] extra parameters passed to OpenAI::Client#chat
    # @yield [Hash] Stream responses back one token at a time
    # @return [Langchain::LLM::OpenAIResponse] Response object
    #
    def chat(prompt: "", messages: [], context: "", examples: [], **options, &block)
      raise ArgumentError.new(":prompt or :messages argument is expected") if prompt.empty? && messages.empty?

      parameters = compose_parameters @defaults[:chat_completion_model_name], options, &block
      parameters[:messages] = compose_chat_messages(prompt: prompt, messages: messages, context: context, examples: examples)

      if functions
        parameters[:functions] = functions
      else
        parameters[:max_tokens] = validate_max_tokens(parameters[:messages], parameters[:model], parameters[:max_tokens])
      end

      response = with_api_error_handling { client.chat(parameters: parameters) }

      return if block

      Langchain::LLM::OpenAIResponse.new(response)
    end

    #
    # Generate a summary for a given text
    #
    # @param text [String] The text to generate a summary for
    # @return [String] The summary
    #
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(prompt: prompt, temperature: @defaults[:temperature])
      # Should this return a Langchain::LLM::OpenAIResponse as well?
    end

    private

    def is_legacy_model?(model)
      LEGACY_COMPLETION_MODELS.any? { |legacy_model| model.include?(legacy_model) }
    end

    def legacy_complete(prompt, parameters)
      Langchain.logger.warn "DEPRECATION WARNING: The model #{parameters[:model]} is deprecated. Please use gpt-3.5-turbo instead. Details: https://platform.openai.com/docs/deprecations/2023-07-06-gpt-and-embeddings"

      parameters[:prompt] = prompt
      parameters[:max_tokens] = validate_max_tokens(prompt, parameters[:model])

      response = with_api_error_handling do
        client.completions(parameters: parameters)
      end
      response.dig("choices", 0, "text")
    end

    def compose_parameters(model, params, &block)
      default_params = {model: model, temperature: @defaults[:temperature], n: @defaults[:n]}
      default_params[:stop] = params.delete(:stop_sequences) if params[:stop_sequences]
      parameters = default_params.merge(params)

      if block
        parameters[:stream] = proc do |chunk, _bytesize|
          yield chunk.dig("choices", 0)
        end
      end

      parameters
    end

    def compose_chat_messages(prompt:, messages: [], context: "", examples: [])
      history = []

      history.concat transform_messages(examples) unless examples.empty?

      history.concat transform_messages(messages) unless messages.empty?

      unless context.nil? || context.empty?
        history.reject! { |message| message[:role] == "system" }
        history.prepend({role: "system", content: context})
      end

      unless prompt.empty?
        if history.last && history.last[:role] == "user"
          history.last[:content] += "\n#{prompt}"
        else
          history.append({role: "user", content: prompt})
        end
      end

      history
    end

    def transform_messages(messages)
      messages.map do |message|
        {
          role: message[:role],
          content: message[:content]
        }
      end
    end

    def with_api_error_handling
      response = yield
      return if response.empty?

      raise Langchain::LLM::ApiError.new "OpenAI API error: #{response.dig("error", "message")}" if response&.dig("error")

      response
    end

    def validate_max_tokens(messages, model, max_tokens = nil)
      LENGTH_VALIDATOR.validate_max_tokens!(messages, model, max_tokens: max_tokens)
    end

    def extract_response(response)
      results = response.dig("choices").map { |choice| choice.dig("message", "content") }
      (results.size == 1) ? results.first : results
    end
  end
end

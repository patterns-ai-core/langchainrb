# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around the Google PaLM (Pathways Language Model) APIs: https://ai.google/build/machine-learning/
  #
  # Gem requirements:
  #     NOPE   gem "google_palm_api", "~> 0.1.3"
  #     NEWRICC gem 'google-cloud-ai_platform', '~> 0.2.0'
  #                  google-apis-aiplatform_v1"
  #
  #   Lets try to keep a single GooglePalmRespomnse - if it doesnt work wee change it.
  #         Currently it only works with gcloud auth application-default login
  #
  # Usage:
  #     google_palm = Langchain::LLM::GooglePalm.new(api_key: ENV["GOOGLE_PALM_API_KEY"])
  #
  class GoogleVertexAi < Base
    DEFAULTS = {
      temperature: 0.2,
      dimension: 768, # This is what the `embedding-gecko-001` model generates
      #TODO completion_model_name: "text-bison-001",
      #TODO chat_completion_model_name: "chat-bison-001",
      #project_id: 'ricc-genai', # TODO(ricc): move below once it works!
      embeddings_model_name: "textembedding-gecko" # non "embedding-gecko-001" (palm)
    }.freeze
    LENGTH_VALIDATOR = Langchain::Utils::TokenLength::GooglePalmValidator
    ROLE_MAPPING = {
      "assistant" => "ai"
    }

    def initialize(api_key_file: nil, project_id: , default_options: {})
      #depends_on 'google/cloud/ai_platform'
      #depends_on 'google/cloud/ai_platform/v1'
      #depends on "google/apis/aiplatform_v1"
      raise "ProjectId is (now) needed as its baked into the API query" if project_id.nil?
      @project_id = project_id

      # TODO(ricc): api_key_file is not needed, could just use ApplicationDEfaultCredentials.
      @client = Google::Apis::AiplatformV1::AiplatformService.new
      @client.root_url = "https://us-central1-aiplatform.googleapis.com/"
      @client.authorization = Google::Auth.get_application_default

      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Langchain::LLM::GooglePalmResponse] Response object
    #
    def embed(text:)
      arrayOfContentHashes = [{content: text }]
      request = Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictRequest.new(instances: arrayOfContentHashes)

      api_path = "projects/#{ @project_id }/locations/us-central1/publishers/google/models/#{ @defaults[:embeddings_model_name] }"

      puts("api_path: #{api_path}")

      response = client.predict_project_location_publisher_model(api_path, request)

      #response = client.embed(text: text)

      Langchain::LLM::GooglePalmResponse.new(response, model: @defaults[:embeddings_model_name])
      # Is the return correct?
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params extra parameters passed to GooglePalmAPI::Client#generate_text
    # @return [Langchain::LLM::GooglePalmResponse] Response object
    #
    def complete(prompt:, **params)
      default_params = {
        prompt: prompt,
        temperature: @defaults[:temperature],
        model: @defaults[:completion_model_name]
      }

      if params[:stop_sequences]
        default_params[:stop_sequences] = params.delete(:stop_sequences)
      end

      if params[:max_tokens]
        default_params[:max_output_tokens] = params.delete(:max_tokens)
      end

      default_params.merge!(params)

      response = client.generate_text(**default_params)

      Langchain::LLM::GooglePalmResponse.new response,
        model: default_params[:model]
    end

    #
    # Generate a chat completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a chat completion for
    # @param messages [Array<Hash>] The messages that have been sent in the conversation
    # @param context [String] An initial context to provide as a system message, ie "You are RubyGPT, a helpful chat bot for helping people learn Ruby"
    # @param examples [Array<Hash>] Examples of messages to provide to the model. Useful for Few-Shot Prompting
    # @param options [Hash] extra parameters passed to GooglePalmAPI::Client#generate_chat_message
    # @return [Langchain::LLM::GooglePalmResponse] Response object
    #
    def chat(prompt: "", messages: [], context: "", examples: [], **options)
      raise ArgumentError.new(":prompt or :messages argument is expected") if prompt.empty? && messages.empty?

      default_params = {
        temperature: @defaults[:temperature],
        model: @defaults[:chat_completion_model_name],
        context: context,
        messages: compose_chat_messages(prompt: prompt, messages: messages),
        examples: compose_examples(examples)
      }

      # chat-bison-001 is the only model that currently supports countMessageTokens functions
      LENGTH_VALIDATOR.validate_max_tokens!(default_params[:messages], "chat-bison-001", llm: self)

      if options[:stop_sequences]
        default_params[:stop] = options.delete(:stop_sequences)
      end

      if options[:max_tokens]
        default_params[:max_output_tokens] = options.delete(:max_tokens)
      end

      default_params.merge!(options)

      response = client.generate_chat_message(**default_params)
      raise "GooglePalm API returned an error: #{response}" if response.dig("error")

      Langchain::LLM::GooglePalmResponse.new response,
        model: default_params[:model]
      # TODO: Pass in prompt_tokens: prompt_tokens
    end

    #
    # Generate a summarization for a given text
    #
    # @param text [String] The text to generate a summarization for
    # @return [String] The summarization
    #
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(
        prompt: prompt,
        temperature: @defaults[:temperature],
        # Most models have a context length of 2048 tokens (except for the newest models, which support 4096).
        max_tokens: 2048
      )
    end

    private

    def compose_chat_messages(prompt:, messages:)
      history = []
      history.concat transform_messages(messages) unless messages.empty?

      unless prompt.empty?
        if history.last && history.last[:role] == "user"
          history.last[:content] += "\n#{prompt}"
        else
          history.append({author: "user", content: prompt})
        end
      end
      history
    end

    def compose_examples(examples)
      examples.each_slice(2).map do |example|
        {
          input: {content: example.first[:content]},
          output: {content: example.last[:content]}
        }
      end
    end

    def transform_messages(messages)
      messages.map do |message|
        {
          author: ROLE_MAPPING.fetch(message[:role], message[:role]),
          content: message[:content]
        }
      end
    end
  end
end

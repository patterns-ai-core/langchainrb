# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around the Google Vertex AI APIs: https://cloud.google.com/vertex-ai?hl=en
  #
  # Gem requirements:
  #     gem "google-apis-aiplatform_v1", "~> 0.7"
  #
  # Usage:
  #     google_palm = Langchain::LLM::GoogleVertexAi.new(project_id: ENV["GOOGLE_VERTEX_AI_PROJECT_ID"])
  #
  class GoogleVertexAi < Base
    DEFAULTS = {
      temperature: 0.1, # 0.1 is the default in the API, quite low ("grounded")
      max_output_tokens: 1000,
      top_p: 0.8,
      top_k: 40,
      dimension: 768,
      completion_model_name: "text-bison", # Optional: tect-bison@001
      embeddings_model_name: "textembedding-gecko"
    }.freeze

    # Google Cloud has a project id and a specific region of deployment.
    # For GenAI-related things, a safe choice is us-central1.
    attr_reader :project_id, :client, :region

    def initialize(project_id:, default_options: {})
      depends_on "google-apis-aiplatform_v1"

      @project_id = project_id
      @region = default_options.fetch :region, "us-central1"

      @client = Google::Apis::AiplatformV1::AiplatformService.new

      # TODO: Adapt for other regions; Pass it in via the constructor
      # For the moment only us-central1 available so no big deal.
      @client.root_url = "https://#{@region}-aiplatform.googleapis.com/"
      @client.authorization = Google::Auth.get_application_default

      @defaults = DEFAULTS.merge(default_options)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @return [Langchain::LLM::GoogleVertexAiResponse] Response object
    #
    def embed(text:)
      content = [{content: text}]
      request = Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictRequest.new(instances: content)

      api_path = "projects/#{@project_id}/locations/us-central1/publishers/google/models/#{@defaults[:embeddings_model_name]}"

      # puts("api_path: #{api_path}")

      response = client.predict_project_location_publisher_model(api_path, request)

      Langchain::LLM::GoogleVertexAiResponse.new(response.to_h, model: @defaults[:embeddings_model_name])
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
        top_k: @defaults[:top_k],
        top_p: @defaults[:top_p],
        max_output_tokens: @defaults[:max_output_tokens],
        model: @defaults[:completion_model_name]
      }

      if params[:stop_sequences]
        default_params[:stop_sequences] = params.delete(:stop_sequences)
      end

      if params[:max_output_tokens]
        default_params[:max_output_tokens] = params.delete(:max_output_tokens)
      end

      # to be tested
      temperature = params.delete(:temperature) || @defaults[:temperature]
      max_output_tokens = default_params.fetch(:max_output_tokens, @defaults[:max_output_tokens])

      default_params.merge!(params)

      # response = client.generate_text(**default_params)
      request = Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictRequest.new \
        instances: [{
          prompt: prompt # key used to be :content, changed to :prompt
        }],
        parameters: {
          temperature: temperature,
          maxOutputTokens: max_output_tokens,
          topP: 0.8,
          topK: 40
        }

      response = client.predict_project_location_publisher_model \
        "projects/#{project_id}/locations/us-central1/publishers/google/models/#{@defaults[:completion_model_name]}",
        request

      Langchain::LLM::GoogleVertexAiResponse.new(response, model: default_params[:model])
    end

    #
    # Generate a summarization for a given text
    #
    # @param text [String] The text to generate a summarization for
    # @return [String] The summarization
    #
    # TODO(ricc): add params for Temp, topP, topK, MaxTokens and have it default to these 4 values.
    def summarize(text:)
      prompt_template = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/llm/prompts/summarize_template.yaml")
      )
      prompt = prompt_template.format(text: text)

      complete(
        prompt: prompt,
        # For best temperature, topP, topK, MaxTokens for summarization: see
        # https://cloud.google.com/vertex-ai/docs/samples/aiplatform-sdk-summarization
        temperature: 0.2,
        top_p: 0.95,
        top_k: 40,
        # Most models have a context length of 2048 tokens (except for the newest models, which support 4096).
        max_output_tokens: 256
      )
    end

    def chat(...)
      # https://cloud.google.com/vertex-ai/docs/samples/aiplatform-sdk-chathat
      # Chat params: https://cloud.google.com/vertex-ai/docs/samples/aiplatform-sdk-chat
      # \"temperature\": 0.3,\n"
      #       + "  \"maxDecodeSteps\": 200,\n"
      #       + "  \"topP\": 0.8,\n"
      #       + "  \"topK\": 40\n"
      #       + "}";
      raise NotImplementedError, "coming soon for Vertex AI.."
    end
  end
end

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
      temperature: 0.2,
      dimension: 768,
      embeddings_model_name: "textembedding-gecko"
    }.freeze

    attr_reader :project_id, :client

    def initialize(project_id:, default_options: {})
      depends_on "google-apis-aiplatform_v1"

      @project_id = project_id

      @client = Google::Apis::AiplatformV1::AiplatformService.new

      # TODO: Adapt for other regions; Pass it in via the constructor
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
      content = [{content: text}]
      request = Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictRequest.new(instances: content)

      api_path = "projects/#{@project_id}/locations/us-central1/publishers/google/models/#{@defaults[:embeddings_model_name]}"

      puts("api_path: #{api_path}")

      response = client.predict_project_location_publisher_model(api_path, request)

      Langchain::LLM::GoogleVertexAiResponse.new(response.to_h, model: @defaults[:embeddings_model_name])
    end
  end
end

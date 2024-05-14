# frozen_string_literal: true

module Langchain::LLM
  #
  # Wrapper around the Google Vertex AI APIs: https://cloud.google.com/vertex-ai
  #
  # Gem requirements:
  #     gem "googleauth"
  #
  # Usage:
  #     llm = Langchain::LLM::GoogleVertexAI.new(project_id: ENV["GOOGLE_VERTEX_AI_PROJECT_ID"], region: "us-central1")
  #
  class GoogleVertexAI < Base
    DEFAULTS = {
      temperature: 0.1,
      max_output_tokens: 1000,
      top_p: 0.8,
      top_k: 40,
      dimensions: 768,
      embeddings_model_name: "textembedding-gecko",
      chat_completion_model_name: "gemini-1.0-pro"
    }.freeze

    # Google Cloud has a project id and a specific region of deployment.
    # For GenAI-related things, a safe choice is us-central1.
    attr_reader :defaults, :url, :authorizer

    def initialize(project_id:, region:, default_options: {})
      depends_on "googleauth"

      @authorizer = ::Google::Auth.get_application_default
      proj_id = project_id || @authorizer.project_id || @authorizer.quota_project_id
      @url = "https://#{region}-aiplatform.googleapis.com/v1/projects/#{proj_id}/locations/#{region}/publishers/google/models/"

      @defaults = DEFAULTS.merge(default_options)

      chat_parameters.update(
        model: {default: @defaults[:chat_completion_model_name]},
        temperature: {default: @defaults[:temperature]}
      )
      chat_parameters.remap(
        messages: :contents,
        system: :system_instruction,
        tool_choice: :tool_config
      )
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param model [String] ID of the model to use
    # @return [Langchain::LLM::GoogleGeminiResponse] Response object
    #
    def embed(
      text:,
      model: @defaults[:embeddings_model_name]
    )
      params = {instances: [{content: text}]}

      response = HTTParty.post(
        "#{url}#{model}:predict",
        body: params.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@authorizer.fetch_access_token!["access_token"]}"
        }
      )

      Langchain::LLM::GoogleGeminiResponse.new(response, model: model)
    end

    # Generate a chat completion for given messages
    #
    # @param messages [Array<Hash>] Input messages
    # @param model [String] The model that will complete your prompt
    # @param tools [Array<Hash>] The tools to use
    # @param tool_choice [String] The tool choice to use
    # @param system [String] The system instruction to use
    # @return [Langchain::LLM::GoogleGeminiResponse] Response object
    def chat(params = {})
      params[:system] = {parts: [{text: params[:system]}]} if params[:system]
      params[:tools] = {function_declarations: params[:tools]} if params[:tools]
      params[:tool_choice] = {function_calling_config: {mode: params[:tool_choice].upcase}} if params[:tool_choice]

      raise ArgumentError.new("messages argument is required") if Array(params[:messages]).empty?

      parameters = chat_parameters.to_params(params)
      parameters[:generation_config] = {temperature: parameters.delete(:temperature)} if parameters[:temperature]

      uri = URI("#{url}#{parameters[:model]}:generateContent")

      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{@authorizer.fetch_access_token!["access_token"]}"
      request.body = parameters.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      parsed_response = JSON.parse(response.body)

      Langchain::LLM::GoogleGeminiResponse.new(parsed_response, model: parameters[:model])
    end
  end
end

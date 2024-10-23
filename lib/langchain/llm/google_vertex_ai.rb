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
      embedding_model: "textembedding-gecko",
      chat_model: "gemini-1.0-pro"
    }.freeze

    # Google Cloud has a project id and a specific region of deployment.
    # For GenAI-related things, a safe choice is us-central1.
    attr_reader :defaults, :url, :authorizer

    def initialize(project_id:, region:, default_options: {})
      depends_on "googleauth"

      @authorizer = ::Google::Auth.get_application_default(scope: [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/generative-language.retriever"
      ])
      proj_id = project_id || @authorizer.project_id || @authorizer.quota_project_id
      @url = "https://#{region}-aiplatform.googleapis.com/v1/projects/#{proj_id}/locations/#{region}/publishers/google/models/"

      @defaults = DEFAULTS.merge(default_options)

      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {default: @defaults[:temperature]},
        safety_settings: {default: @defaults[:safety_settings]}
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
      model: @defaults[:embedding_model]
    )
      params = {instances: [{content: text}]}

      uri = URI("#{url}#{model}:predict")

      parsed_response = http_post(uri, params)

      Langchain::LLM::GoogleGeminiResponse.new(parsed_response, model: model)
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

      raise ArgumentError.new("messages argument is required") if Array(params[:messages]).empty?

      parameters = chat_parameters.to_params(params)
      parameters[:generation_config] = {temperature: parameters.delete(:temperature)} if parameters[:temperature]

      uri = URI("#{url}#{parameters[:model]}:generateContent")

      parsed_response = http_post(uri, parameters)

      wrapped_response = Langchain::LLM::GoogleGeminiResponse.new(parsed_response, model: parameters[:model])

      if wrapped_response.chat_completion || Array(wrapped_response.tool_calls).any?
        wrapped_response
      else
        raise StandardError.new(parsed_response)
      end
    end

    private

    def http_post(url, params)
      http = Net::HTTP.new(url.hostname, url.port)
      http.use_ssl = url.scheme == "https"
      http.set_debug_output(Langchain.logger) if Langchain.logger.debug?

      request = Net::HTTP::Post.new(url)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{@authorizer.fetch_access_token!["access_token"]}"
      request.body = params.to_json

      response = http.request(request)

      JSON.parse(response.body)
    end
  end
end

# frozen_string_literal: true

module Langchain::LLM
  # Usage:
  #     llm = Langchain::LLM::GoogleGemini.new(api_key: ENV['GOOGLE_GEMINI_API_KEY'])
  class GoogleGemini < Base
    DEFAULTS = {
      chat_completion_model_name: "gemini-1.5-pro-latest",
      embeddings_model_name: "text-embedding-004",
      temperature: 0.0
    }

    attr_reader :defaults, :api_key

    def initialize(api_key:, default_options: {})
      @api_key = api_key
      @defaults = DEFAULTS.merge(default_options)

      chat_parameters.update(
        model: {default: @defaults[:chat_completion_model_name]},
        temperature: {default: @defaults[:temperature]},
        generation_config: {default: nil},
        safety_settings: {default: nil}
      )
      chat_parameters.remap(
        messages: :contents,
        system: :system_instruction,
        tool_choice: :tool_config
      )
    end

    # Generate a chat completion for a given prompt
    #
    # @param messages [Array<Hash>] List of messages comprising the conversation so far
    # @param model [String] The model to use
    # @param tools [Array<Hash>] A list of Tools the model may use to generate the next response
    # @param tool_choice [String] Specifies the mode in which function calling should execute. If unspecified, the default value will be set to AUTO. Possible values: AUTO, ANY, NONE
    # @param system [String] Developer set system instruction
    def chat(params = {})
      params[:system] = {parts: [{text: params[:system]}]} if params[:system]
      params[:tools] = {function_declarations: params[:tools]} if params[:tools]

      raise ArgumentError.new("messages argument is required") if Array(params[:messages]).empty?

      parameters = chat_parameters.to_params(params)
      parameters[:generation_config] ||= {}
      parameters[:generation_config][:temperature] ||= parameters[:temperature] if parameters[:temperature]
      parameters.delete(:temperature)
      parameters[:generation_config][:top_p] ||= parameters[:top_p] if parameters[:top_p]
      parameters.delete(:top_p)
      parameters[:generation_config][:top_k] ||= parameters[:top_k] if parameters[:top_k]
      parameters.delete(:top_k)
      parameters[:generation_config][:max_output_tokens] ||= parameters[:max_tokens] if parameters[:max_tokens]
      parameters.delete(:max_tokens)
      parameters[:generation_config][:response_mime_type] ||= parameters[:response_format] if parameters[:response_format]
      parameters.delete(:response_format)
      parameters[:generation_config][:stop_sequences] ||= parameters[:stop] if parameters[:stop]
      parameters.delete(:stop)

      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{parameters[:model]}:generateContent?key=#{api_key}")

      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = parameters.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      parsed_response = JSON.parse(response.body)

      wrapped_response = Langchain::LLM::GoogleGeminiResponse.new(parsed_response, model: parameters[:model])

      if wrapped_response.chat_completion || Array(wrapped_response.tool_calls).any?
        wrapped_response
      else
        raise StandardError.new(parsed_response)
      end
    end

    def embed(
      text:,
      model: @defaults[:embeddings_model_name]
    )

      params = {
        content: {
          parts: [
            {
              text: text
            }
          ]
        }
      }

      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:embedContent?key=#{api_key}")

      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = params.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      parsed_response = JSON.parse(response.body)

      Langchain::LLM::GoogleGeminiResponse.new(parsed_response, model: model)
    end
  end
end

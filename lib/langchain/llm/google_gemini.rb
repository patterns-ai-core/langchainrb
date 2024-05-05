# frozen_string_literal: true

module Langchain::LLM
  # Usage:
  #     llm = Langchain::LLM::GoogleGemini.new(api_key: ENV['GOOGLE_GEMINI_API_KEY'])
  class GoogleGemini < Base
    DEFAULTS = {
      chat_completion_model_name: "gemini-1.5-pro-latest"
    }

    attr_reader :defaults, :api_key

    def initialize(api_key:, default_options: {})
      @api_key = api_key
      @defaults = DEFAULTS.merge(default_options)
    end

    # Generate a chat completion for a given prompt
    #
    # @param messages [Array<Hash>] List of messages comprising the conversation so far
    # @param model [String] The model to use
    # @param tools [Array<Hash>] A list of Tools the model may use to generate the next response
    # @param tool_choice [String] Specifies the mode in which function calling should execute. If unspecified, the default value will be set to AUTO. Possible values: AUTO, ANY, NONE
    # @param system [String] Developer set system instruction
    def chat(
      messages: [],
      model: defaults[:chat_completion_model_name],
      tools: [],
      tool_choice: nil,
      system: nil
    )
      params = {
        contents: messages
      }
      params[:tools] = {function_declarations: tools} if tools.any?
      params[:tool_config] = {function_calling_config: {mode: tool_choice.upcase}} if tool_choice
      # When system_instruction is set, getting: {"error"=>{"code"=>400, "message"=>"Developer instruction is not enabled for models/gemini-pro", "status"=>"INVALID_ARGUMENT"}}
      params[:system_instruction] = {parts: [{text: system}]} if system

      # TODO: Convert this to use Net::HTTP
      response = HTTParty.post(
        "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}",
        body: params.to_json,
        headers: {"Content-Type" => "application/json"}
      )

      if response.code != 200
        raise StandardError.new(response)
      end

      Langchain::LLM::GoogleGeminiResponse.new(response, model: defaults[:chat_completion_model_name])
    end
  end
end

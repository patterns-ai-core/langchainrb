# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Aws Bedrock APIs: https://docs.aws.amazon.com/bedrock/
  #
  # Gem requirements:
  #    gem 'aws-sdk-bedrockruntime', '~> 1.1'
  #
  # Usage:
  #    llm = Langchain::LLM::AwsBedrock.new(default_options: {})
  #
  class AwsBedrock < Base
    DEFAULTS = {
      chat_model: "anthropic.claude-3-5-sonnet-20240620-v1:0",
      completion_model: "anthropic.claude-v2:1",
      embedding_model: "amazon.titan-embed-text-v1",
      max_tokens_to_sample: 300,
      temperature: 1,
      top_k: 250,
      top_p: 0.999,
      stop_sequences: ["\n\nHuman:"],
      return_likelihoods: "NONE"
    }.freeze

    attr_reader :client, :defaults

    SUPPORTED_COMPLETION_PROVIDERS = %i[
      anthropic
      ai21
      cohere
      meta
    ].freeze

    SUPPORTED_CHAT_COMPLETION_PROVIDERS = %i[
      anthropic
      ai21
      mistral
    ].freeze

    SUPPORTED_EMBEDDING_PROVIDERS = %i[
      amazon
      cohere
    ].freeze

    def initialize(aws_client_options: {}, default_options: {})
      depends_on "aws-sdk-bedrockruntime", req: "aws-sdk-bedrockruntime"

      @client = ::Aws::BedrockRuntime::Client.new(**aws_client_options)
      @defaults = DEFAULTS.merge(default_options)

      chat_parameters.update(
        model: {default: @defaults[:chat_model]},
        temperature: {},
        max_tokens: {default: @defaults[:max_tokens_to_sample]},
        metadata: {},
        system: {}
      )
      chat_parameters.ignore(:n, :user)
      chat_parameters.remap(stop: :stop_sequences)
    end

    #
    # Generate an embedding for a given text
    #
    # @param text [String] The text to generate an embedding for
    # @param params extra parameters passed to Aws::BedrockRuntime::Client#invoke_model
    # @return [Langchain::LLM::AwsTitanResponse] Response object
    #
    def embed(text:, **params)
      raise "Completion provider #{embedding_provider} is not supported." unless SUPPORTED_EMBEDDING_PROVIDERS.include?(embedding_provider)

      parameters = compose_embedding_parameters params.merge(text:)

      response = client.invoke_model({
        model_id: @defaults[:embedding_model],
        body: parameters.to_json,
        content_type: "application/json",
        accept: "application/json"
      })

      parse_embedding_response response
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params  extra parameters passed to Aws::BedrockRuntime::Client#invoke_model
    # @return [Langchain::LLM::Response::AnthropicResponse], [Langchain::LLM::Response::CohereResponse] or [Langchain::LLM::AI21Response] Response object
    #
    def complete(
      prompt:,
      model: @defaults[:completion_model],
      **params
    )
      raise "Completion provider #{model} is not supported." unless SUPPORTED_COMPLETION_PROVIDERS.include?(provider_name(model))

      parameters = compose_parameters(params, model)

      parameters[:prompt] = wrap_prompt prompt

      response = client.invoke_model({
        model_id: model,
        body: parameters.to_json,
        content_type: "application/json",
        accept: "application/json"
      })

      parse_response(response, model)
    end

    # Generate a chat completion for a given prompt
    #
    # Anthropic, AI21 and Mistral models are called with InvokeModel in their own request formats.
    # Every other model (Amazon Nova, Meta Llama, Cohere, DeepSeek, OpenAI gpt-oss, ...) is called with the
    # Converse API, which takes the same request for all of them and returns a
    # [Langchain::LLM::Response::AwsBedrockConverseResponse]. With Converse, String message contents and
    # a String `system:` are converted to content blocks, `role: "system"` messages become the system prompt,
    # and `tools:` (OpenAI-style `{type: "function", function: {...}}` or Anthropic-style `{name:, description:, input_schema:}`)
    # and `tool_choice:` are sent as the `tool_config`.
    #
    # @param [Hash] params unified chat parmeters from [Langchain::LLM::Parameters::Chat::SCHEMA]
    # @option params [Array<String>] :messages The messages to generate a completion for
    # @option params [String] :system The system prompt to provide instructions
    # @option params [String] :model The model to use for completion defaults to @defaults[:chat_model]
    # @option params [Integer] :max_tokens The maximum number of tokens to generate defaults to @defaults[:max_tokens_to_sample]
    # @option params [Array<String>] :stop The stop sequences to use for completion
    # @option params [Array<String>] :stop_sequences The stop sequences to use for completion
    # @option params [Float] :temperature The temperature to use for completion
    # @option params [Float] :top_p Use nucleus sampling.
    # @option params [Integer] :top_k Only sample from the top K options for each subsequent token
    # @yield [Hash] Provides chunks of the response as they are received (Converse stream events as hashes for Converse models)
    # @return [Langchain::LLM::Response::AwsBedrockAnthropicResponse], [Langchain::LLM::Response::AwsBedrockConverseResponse] Response object
    def chat(params = {}, &block)
      parameters = chat_parameters.to_params(params)

      unless SUPPORTED_CHAT_COMPLETION_PROVIDERS.include?(provider_name(parameters[:model]))
        return converse(parameters, &block)
      end

      parameters = compose_parameters(parameters, parameters[:model])

      if block
        response_chunks = []

        client.invoke_model_with_response_stream(
          model_id: parameters[:model],
          body: parameters.except(:model).to_json,
          content_type: "application/json",
          accept: "application/json"
        ) do |stream|
          stream.on_event do |event|
            chunk = JSON.parse(event.bytes)
            response_chunks << chunk

            yield chunk
          end
        end

        response_from_chunks(response_chunks)
      else
        response = client.invoke_model({
          model_id: parameters[:model],
          body: parameters.except(:model).to_json,
          content_type: "application/json",
          accept: "application/json"
        })

        parse_response(response, parameters[:model])
      end
    end

    private

    def parse_model_id(model_id)
      model_id
        .gsub(/^(us|us-gov|eu|apac|jp|au|ca|global)\./, "") # Cross-region inference profile IDs start with a geography (or "global.") prefix.
        .split(".")
    end

    def provider_name(model_id)
      parse_model_id(model_id).first.to_sym
    end

    def model_name(model_id)
      parse_model_id(model_id).last
    end

    def completion_provider
      @defaults[:completion_model].split(".").first.to_sym
    end

    def embedding_provider
      @defaults[:embedding_model].split(".").first.to_sym
    end

    def wrap_prompt(prompt)
      if completion_provider == :anthropic
        "\n\nHuman: #{prompt}\n\nAssistant:"
      else
        prompt
      end
    end

    def max_tokens_key
      if completion_provider == :anthropic
        :max_tokens_to_sample
      elsif completion_provider == :cohere
        :max_tokens
      elsif completion_provider == :ai21
        :maxTokens
      end
    end

    def compose_parameters(params, model_id)
      if provider_name(model_id) == :anthropic
        compose_parameters_anthropic(params)
      elsif provider_name(model_id) == :cohere
        compose_parameters_cohere(params)
      elsif provider_name(model_id) == :ai21
        params
      elsif provider_name(model_id) == :meta
        params
      elsif provider_name(model_id) == :mistral
        params
      end
    end

    def compose_embedding_parameters(params)
      if embedding_provider == :amazon
        compose_embedding_parameters_amazon params
      elsif embedding_provider == :cohere
        compose_embedding_parameters_cohere params
      end
    end

    def parse_response(response, model_id)
      if provider_name(model_id) == :anthropic
        Langchain::LLM::Response::AwsBedrockAnthropicResponse.new(JSON.parse(response.body.string))
      elsif provider_name(model_id) == :cohere
        Langchain::LLM::Response::CohereResponse.new(JSON.parse(response.body.string))
      elsif provider_name(model_id) == :ai21
        Langchain::LLM::Response::AI21Response.new(JSON.parse(response.body.string, symbolize_names: true))
      elsif provider_name(model_id) == :meta
        Langchain::LLM::Response::AwsBedrockMetaResponse.new(JSON.parse(response.body.string))
      elsif provider_name(model_id) == :mistral
        Langchain::LLM::Response::MistralAIResponse.new(JSON.parse(response.body.string))
      end
    end

    def parse_embedding_response(response)
      json_response = JSON.parse(response.body.string)

      if embedding_provider == :amazon
        Langchain::LLM::Response::AwsTitanResponse.new(json_response)
      elsif embedding_provider == :cohere
        Langchain::LLM::Response::CohereResponse.new(json_response)
      end
    end

    def compose_embedding_parameters_amazon(params)
      default_params = @defaults.merge(params)

      {
        inputText: default_params[:text],
        dimensions: default_params[:dimensions],
        normalize: default_params[:normalize]
      }.compact
    end

    def compose_embedding_parameters_cohere(params)
      default_params = @defaults.merge(params)

      {
        texts: [default_params[:text]],
        truncate: default_params[:truncate],
        input_type: default_params[:input_type],
        embedding_types: default_params[:embedding_types]
      }.compact
    end

    def compose_parameters_cohere(params)
      default_params = @defaults.merge(params)

      {
        max_tokens: default_params[:max_tokens_to_sample],
        temperature: default_params[:temperature],
        p: default_params[:top_p],
        k: default_params[:top_k],
        stop_sequences: default_params[:stop_sequences]
      }
    end

    def compose_parameters_anthropic(params)
      params.merge(anthropic_version: "bedrock-2023-05-31")
    end

    # Call the Converse API, or ConverseStream when a block is given
    #
    # @param parameters [Hash] The unified chat parameters
    # @return [Langchain::LLM::Response::AwsBedrockConverseResponse]
    def converse(parameters, &block)
      converse_parameters = compose_converse_parameters(parameters)

      raw_response = if block
        converse_stream(converse_parameters, &block)
      else
        client.converse(converse_parameters).to_h
      end

      Langchain::LLM::Response::AwsBedrockConverseResponse.new(stringify_keys(raw_response), model: parameters[:model])
    end

    # Stream a Converse response, yielding every event as a hash, and rebuild the response the Converse API would have returned
    def converse_stream(converse_parameters)
      message = {role: "assistant", content: []}
      raw_response = {output: {message: message}}

      client.converse_stream(converse_parameters) do |stream|
        stream.on_message_start_event { |event| message[:role] = event.role }
        stream.on_content_block_start_event do |event|
          if event.start&.tool_use
            message[:content][event.content_block_index] = {tool_use: event.start.tool_use.to_h.merge(input: +"")}
          end
        end
        stream.on_content_block_delta_event do |event|
          content_block = (message[:content][event.content_block_index] ||= {})
          if event.delta.text
            (content_block[:text] ||= +"") << event.delta.text
          elsif event.delta.tool_use
            content_block[:tool_use][:input] << event.delta.tool_use.input.to_s
          end
        end
        stream.on_message_stop_event { |event| raw_response[:stop_reason] = event.stop_reason }
        stream.on_metadata_event do |event|
          raw_response[:usage] = event.usage.to_h
          raw_response[:metrics] = event.metrics.to_h
        end
        stream.on_event { |event| yield event.to_h }
      end

      message[:content].compact!
      message[:content].each do |content_block|
        next unless content_block[:tool_use]
        input = content_block[:tool_use][:input]
        content_block[:tool_use][:input] = input.empty? ? {} : JSON.parse(input)
      end

      raw_response
    end

    def compose_converse_parameters(parameters)
      system_messages, messages = Array(parameters[:messages]).partition { |message| message_field(message, :role).to_s == "system" }

      system = converse_content(parameters[:system]) + system_messages.flat_map { |message| converse_content(message_field(message, :content)) }
      inference_config = {
        max_tokens: parameters[:max_tokens],
        temperature: parameters[:temperature],
        top_p: parameters[:top_p],
        stop_sequences: parameters[:stop_sequences]
      }.compact

      converse_parameters = {
        model_id: parameters[:model],
        messages: messages.map do |message|
          {role: message_field(message, :role).to_s, content: converse_content(message_field(message, :content))}
        end
      }
      converse_parameters[:system] = system if system.any?
      converse_parameters[:inference_config] = inference_config if inference_config.any?

      tools = Array(parameters[:tools])
      if tools.any?
        converse_parameters[:tool_config] = {tools: tools.map { |tool| converse_tool(symbolize_keys(tool)) }}
        tool_choice = converse_tool_choice(parameters[:tool_choice])
        converse_parameters[:tool_config][:tool_choice] = tool_choice if tool_choice
      end

      converse_parameters
    end

    def message_field(message, key)
      message[key] || message[key.to_s]
    end

    # @return [Array<Hash>] String content as a text block; content blocks are passed as-is
    def converse_content(content)
      case content
      when nil then []
      when String then [{text: content}]
      when Array then content.map { |block| block.is_a?(String) ? {text: block} : symbolize_keys(block) }
      else [symbolize_keys(content)]
      end
    end

    def converse_tool(tool)
      return tool if tool.key?(:tool_spec)

      function = tool[:function] || tool
      schema = function[:parameters] || function[:input_schema] || {type: "object", properties: {}}
      {tool_spec: {name: function[:name], description: function[:description], input_schema: {json: schema}}.compact}
    end

    # Converse has no "none" tool choice, so "none" (like nil) leaves the choice to the model
    def converse_tool_choice(choice)
      case choice
      when nil, "none" then nil
      when Hash then choice
      when "auto" then {auto: {}}
      when "any", "required" then {any: {}}
      else {tool: {name: choice.to_s}}
      end
    end

    def symbolize_keys(value)
      case value
      when Hash then value.to_h { |k, v| [k.to_sym, symbolize_keys(v)] }
      when Array then value.map { |v| symbolize_keys(v) }
      else value
      end
    end

    def stringify_keys(value)
      case value
      when Hash then value.to_h { |k, v| [k.to_s, stringify_keys(v)] }
      when Array then value.map { |v| stringify_keys(v) }
      else value
      end
    end

    def response_from_chunks(chunks)
      raw_response = {}

      chunks.group_by { |chunk| chunk["type"] }.each do |type, chunks|
        case type
        when "message_start"
          raw_response = chunks.first["message"]
        when "content_block_start"
          raw_response["content"] = chunks.map { |chunk| chunk["content_block"] }
        when "content_block_delta"
          chunks.group_by { |chunk| chunk["index"] }.each do |index, deltas|
            deltas.group_by { |delta| delta.dig("delta", "type") }.each do |type, deltas|
              case type
              when "text_delta"
                raw_response["content"][index]["text"] = deltas.map { |delta| delta.dig("delta", "text") }.join
              when "input_json_delta"
                json_string = deltas.map { |delta| delta.dig("delta", "partial_json") }.join
                raw_response["content"][index]["input"] = json_string.empty? ? {} : JSON.parse(json_string)
              end
            end
          end
        when "message_delta"
          chunks.each do |chunk|
            raw_response = raw_response.merge(chunk["delta"])
            raw_response["usage"] = raw_response["usage"].merge(chunk["usage"]) if chunk["usage"]
          end
        end
      end

      Langchain::LLM::Response::AwsBedrockAnthropicResponse.new(raw_response)
    end
  end
end

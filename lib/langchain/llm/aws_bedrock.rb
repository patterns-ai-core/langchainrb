# frozen_string_literal: true

module Langchain::LLM
  # LLM interface for Aws Bedrock APIs: https://docs.aws.amazon.com/bedrock/
  #
  # Gem requirements:
  #    gem 'aws-sdk-bedrockruntime', '~> 1.1'
  #
  # Usage:
  #    bedrock = Langchain::LLM::AwsBedrock.new(llm_options: {})
  #
  class AwsBedrock < Base
    ANTHROPIC_CLAUDE_DEFAULTS = {
      completion_model_name: "anthropic.claude-v2",
      max_tokens_to_sample: 300,
      temperature: 1,
      top_k: 250,
      top_p: 0.999,
      stop_sequences: ["\n\nHuman:"],
      anthropic_version: "bedrock-2023-05-31"
    }

    attr_accessor :functions

    def initialize(llm_options: {}, anthropic_default_options: {})
      depends_on "aws-sdk-bedrockruntime", req: "aws-sdk-bedrockruntime"

      @client = ::Aws::BedrockRuntime::Client.new(**llm_options)
      @anthropic_defaults = ANTHROPIC_CLAUDE_DEFAULTS.merge(anthropic_default_options)
    end

    #
    # Generate a completion for a given prompt
    #
    # @param prompt [String] The prompt to generate a completion for
    # @param params  extra parameters passed to Aws::BedrockRuntime::Client#invoke_model
    # @return [Langchain::LLM::AnthropicResponse] Response object
    #
    def complete(prompt:, **params)
      parameters = compose_parameters_anthropic params

      parameters[:prompt] = "\n\nHuman: #{prompt}\n\nAssistant:"
      # TODO: Implement token length validator for Anthropic
      # parameters[:max_tokens_to_sample] = validate_max_tokens(prompt, parameters[:completion_model_name])

      response = client.invoke_model({
        model_id: @anthropic_defaults[:completion_model_name],
        body: parameters.to_json,
        content_type: "application/json",
        accept: "application/json"
      })

      Langchain::LLM::AnthropicResponse.new(JSON.parse(response.body.string))
    end

    private

    def compose_parameters_anthropic(params)
      default_params = @anthropic_defaults.except(:completion_model_name)

      default_params.merge(params)
    end

    # TODO: Implement token length validator for Anthropic
    # def validate_max_tokens(messages, model)
    #   LENGTH_VALIDATOR.validate_max_tokens!(messages, model)
    # end
  end
end

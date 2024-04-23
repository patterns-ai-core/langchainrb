# frozen_string_literal: true

require "delegate"

module Langchain::LLM::Parameters
  class Chat < SimpleDelegator
    # TODO: At the moment, the UnifiedParamters only considers keys.  In the
    # future, we'll consider ActiveModel-style validations and further typed
    # options here.
    SCHEMA = {
      # Either "messages" or "prompt" is required
      messages: Array,
      prompt: String,

      # Allows to force the model to produce specific output format.
      response_format: String,

      stop: String, # TODO: handle multiple types (e.g. OpenAI also allows Array, null)
      stream: TrueClass, # Enable streaming

      max_tokens: Integer, # Range: [1, context_length)
      temperature: Integer, # Range: [0, 2]
      top_p: Integer, # Range: (0, 1]
      top_k: Integer, # Range: [1, Infinity) Not available for OpenAI models
      frequency_penalty: Integer, # Range: [-2, 2]
      presence_penalty: Integer, # Range: [-2, 2]
      repetition_penalty: Integer, # Range: (0, 2]
      seed: Integer, # OpenAI only

      # Function-calling
      # Only natively suported by OpenAI models. For others, we submit
      # a YAML-formatted string with these tools at the end of the prompt.
      tools: Array, # TODO: consider what validating Tool objects here looks like
      tool_choice: Hash, # TODO: consider what validating a ToolChoice object would look like

      # Additional optional parameters
      logit_bias: Hash # TODO: consider validating this as Map { [key: number]: number },
    }

    def initialize(parameters: {}, aliases: {})
      super(
        ::Langchain::LLM::UnifiedParameters.new(
          schema: SCHEMA,
          aliases: aliases,
          parameters: parameters
        )
      )
    end

    def self.call(params, aliases: {})
      new(parameters: params, aliases: aliases).to_params
    end
  end
end

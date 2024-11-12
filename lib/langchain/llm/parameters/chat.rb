# frozen_string_literal: true

require "delegate"

module Langchain::LLM::Parameters
  class Chat < SimpleDelegator
    # TODO: At the moment, the UnifiedParamters only considers keys.  In the
    # future, we may consider ActiveModel-style validations and further typed
    # options here.
    SCHEMA = {
      # Either "messages" or "prompt" is required
      messages: {},
      model: {},
      prompt: {},

      # System instructions. Used by Cohere, Anthropic and Google Gemini.
      system: {},

      # Allows to force the model to produce specific output format.
      response_format: {},

      stop: {}, # multiple types (e.g. OpenAI also allows Array, null)
      stream: {}, # Enable streaming

      max_tokens: {}, # Range: [1, context_length)
      temperature: {}, # Range: [0, 2]
      top_p: {}, # Range: (0, 1]
      top_k: {}, # Range: [1, Infinity) Not available for OpenAI models
      frequency_penalty: {}, # Range: [-2, 2]
      presence_penalty: {}, # Range: [-2, 2]
      repetition_penalty: {}, # Range: (0, 2]
      seed: {}, # OpenAI only

      # Function-calling
      tools: {default: []},
      tool_choice: {},
      parallel_tool_calls: {},

      # Additional optional parameters
      logit_bias: {},

      # Additional llm options. Ollama only.
      options: {}
    }

    def initialize(parameters: {})
      super(
        ::Langchain::LLM::UnifiedParameters.new(
          schema: SCHEMA.dup,
          parameters: parameters
        )
      )
    end
  end
end

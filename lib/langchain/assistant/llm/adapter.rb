# frozen_string_literal: true

module Langchain
  class Assistant
    module LLM
      # TODO: Fix the message truncation when context window is exceeded
      class Adapter
        def self.build(llm)
          case llm
          when Langchain::LLM::Anthropic
            LLM::Adapters::Anthropic.new
          when Langchain::LLM::GoogleGemini, Langchain::LLM::GoogleVertexAI
            LLM::Adapters::GoogleGemini.new
          when Langchain::LLM::MistralAI
            LLM::Adapters::MistralAI.new
          when Langchain::LLM::Ollama
            LLM::Adapters::Ollama.new
          when Langchain::LLM::OpenAI
            LLM::Adapters::OpenAI.new
          else
            raise ArgumentError, "Unsupported LLM type: #{llm.class}"
          end
        end
      end
    end
  end
end

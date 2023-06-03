module Langchain
  module LLM
    autoload :Base, "langchain/llm/base"
    autoload :Cohere, "langchain/llm/cohere"
    autoload :GooglePalm, "langchain/llm/google_palm"
    autoload :HuggingFace, "langchain/llm/hugging_face"
    autoload :OpenAI, "langchain/llm/openai"
    autoload :Replicate, "langchain/llm/replicate"

    # Currently supported LLMs
    BUILTIN = {
      cohere: "Cohere",
      google_palm: "GooglePalm",
      huggingface: "HuggingFace",
      openai: "OpenAI",
      replicate: "Replicate"
    }.freeze

    def build(llm, api_key:)
      unless supported?(llm)
        raise ArgumentError, "LLM must be one of #{Langchain::LLM::BUILTIN.keys}"
      end

      llm_class_name = Langchain::LLM::BUILTIN.fetch(llm)
      llm_class = Langchain::LLM.const_get(llm_class_name)
      llm_class.new(api_key: api_key)
    end

    def reuse_or_build(llm, api_key:)
      @llm_client = if llm.is_a?(Langchain::LLM::Base)
        llm
      else
        build(llm, api_key: api_key)
      end
    end

    def supported?(llm)
      BUILTIN.key?(llm.to_sym)
    end

    extend self
  end
end

# frozen_string_literal: true

require "logger"
require "pathname"
require "colorize"

require_relative "./version"
require_relative "./dependency_helper"

module Langchain
  class << self
    attr_accessor :logger

    attr_reader :root
  end

  @logger ||= ::Logger.new($stdout, level: :warn, formatter: ->(severity, datetime, progname, msg) { "[LangChain.rb]".yellow + " #{msg}\n" })

  @root = Pathname.new(__dir__)

  autoload :Loader, "langchain/loader"
  autoload :Data, "langchain/data"

  module Agent
    autoload :Base, "langchain/agent/base"
    autoload :ChainOfThoughtAgent, "langchain/agent/chain_of_thought_agent/chain_of_thought_agent.rb"
  end

  module Tool
    autoload :Base, "langchain/tool/base"
    autoload :Calculator, "langchain/tool/calculator"
    autoload :SerpApi, "langchain/tool/serp_api"
    autoload :Wikipedia, "langchain/tool/wikipedia"
  end

  module Processors
    autoload :Base, "langchain/processors/base"
    autoload :CSV, "langchain/processors/csv"
    autoload :Docx, "langchain/processors/docx"
    autoload :HTML, "langchain/processors/html"
    autoload :JSON, "langchain/processors/json"
    autoload :JSONL, "langchain/processors/jsonl"
    autoload :PDF, "langchain/processors/pdf"
    autoload :Text, "langchain/processors/text"
  end

  module Utils
    autoload :TokenLengthValidator, "langchain/utils/token_length_validator"
  end

  module Vectorsearch
    autoload :Base, "langchain/vectorsearch/base"
    autoload :Chroma, "langchain/vectorsearch/chroma"
    autoload :Milvus, "langchain/vectorsearch/milvus"
    autoload :Pinecone, "langchain/vectorsearch/pinecone"
    autoload :Pgvector, "langchain/vectorsearch/pgvector"
    autoload :Qdrant, "langchain/vectorsearch/qdrant"
    autoload :Weaviate, "langchain/vectorsearch/weaviate"
  end

  module LLM
    autoload :Base, "langchain/llm/base"
    autoload :Cohere, "langchain/llm/cohere"
    autoload :GooglePalm, "langchain/llm/google_palm"
    autoload :HuggingFace, "langchain/llm/hugging_face"
    autoload :OpenAI, "langchain/llm/openai"
    autoload :Replicate, "langchain/llm/replicate"
  end

  module Prompt
    require_relative "langchain/prompt/loading"

    autoload :Base, "langchain/prompt/base"
    autoload :PromptTemplate, "langchain/prompt/prompt_template"
    autoload :FewShotPromptTemplate, "langchain/prompt/few_shot_prompt_template"
  end
end

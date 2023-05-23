# frozen_string_literal: true

require "logger"

require_relative "./version"
require_relative "./dependency_helper"
module Langchain
  class << self
    attr_accessor :logger

    attr_reader :root
  end

  @logger ||= ::Logger.new($stdout, level: :warn, formatter: ->(severity, datetime, progname, msg) { "[LangChain.rb] #{msg}\n" })

  @root = Pathname.new(__dir__)
end

module Agent
  autoload :Base, "agent/base"
  autoload :ChainOfThoughtAgent, "agent/chain_of_thought_agent/chain_of_thought_agent.rb"
end

module Vectorsearch
  autoload :Base, "vectorsearch/base"
  autoload :Chroma, "vectorsearch/chroma"
  autoload :Milvus, "vectorsearch/milvus"
  autoload :Pinecone, "vectorsearch/pinecone"
  autoload :Qdrant, "vectorsearch/qdrant"
  autoload :Weaviate, "vectorsearch/weaviate"
end

module LLM
  autoload :Base, "llm/base"
  autoload :Cohere, "llm/cohere"
  autoload :HuggingFace, "llm/hugging_face"
  autoload :OpenAI, "llm/openai"
  autoload :Replicate, "llm/replicate"
end

module Prompt
  require_relative "prompt/loading"

  autoload :Base, "prompt/base"
  autoload :PromptTemplate, "prompt/prompt_template"
  autoload :FewShotPromptTemplate, "prompt/few_shot_prompt_template"
end

module Tool
  autoload :Base, "tool/base"
  autoload :Calculator, "tool/calculator"
  autoload :SerpApi, "tool/serp_api"
  autoload :Wikipedia, "tool/wikipedia"
end

module Loaders
  autoload :Base, "loaders/base"
  module Processors
    autoload :PDF, "loaders/processors/pdf"
    autoload :HTML, "loaders/processors/html"
    autoload :Text, "loaders/processors/text"
    autoload :Docx, "loaders/processors/docx"
  end
end

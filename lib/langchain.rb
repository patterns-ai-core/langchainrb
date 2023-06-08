# frozen_string_literal: true

require "logger"
require "pathname"
require "colorize"

require_relative "./langchain/version"

module Langchain
  class << self
    # @return [Logger]
    attr_accessor :logger

    # @return [Pathname]
    attr_reader :root
  end

  @logger ||= ::Logger.new($stdout, level: :warn, formatter: ->(severity, datetime, progname, msg) { "[LangChain.rb]".yellow + " #{msg}\n" })

  @root = Pathname.new(__dir__)

  autoload :Loader, "langchain/loader"
  autoload :Data, "langchain/data"
  autoload :DependencyHelper, "langchain/dependency_helper"

  module Agent
    autoload :Base, "langchain/agent/base"
    autoload :ChainOfThoughtAgent, "langchain/agent/chain_of_thought_agent/chain_of_thought_agent.rb"
    autoload :SQLQueryAgent, "langchain/agent/sql_query_agent/sql_query_agent.rb"
  end

  module Tool
    autoload :Base, "langchain/tool/base"
    autoload :Calculator, "langchain/tool/calculator"
    autoload :RubyCodeInterpreter, "langchain/tool/ruby_code_interpreter"
    autoload :SerpApi, "langchain/tool/serp_api"
    autoload :Wikipedia, "langchain/tool/wikipedia"
    autoload :Database, "langchain/tool/database"
  end

  # Processors load and parse/process various data types such as CSVs, PDFs, Word documents, HTML pages, and others.
  module Processors
    autoload :Base, "langchain/processors/base"
    autoload :CSV, "langchain/processors/csv"
    autoload :Docx, "langchain/processors/docx"
    autoload :HTML, "langchain/processors/html"
    autoload :JSON, "langchain/processors/json"
    autoload :JSONL, "langchain/processors/jsonl"
    autoload :PDF, "langchain/processors/pdf"
    autoload :Text, "langchain/processors/text"
    autoload :Xlsx, "langchain/processors/xlsx"
  end

  module Utils
    autoload :TokenLengthValidator, "langchain/utils/token_length_validator"
  end

  # Vector database is a type of database that stores data as high-dimensional vectors, which are mathematical representations of features or attributes. Each vector has a certain number of dimensions, which can range from tens to thousands, depending on the complexity and granularity of the data.
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
    autoload :AI21, "langchain/llm/ai21"
    autoload :Base, "langchain/llm/base"
    autoload :Cohere, "langchain/llm/cohere"
    autoload :GooglePalm, "langchain/llm/google_palm"
    autoload :HuggingFace, "langchain/llm/hugging_face"
    autoload :OpenAI, "langchain/llm/openai"
    autoload :Replicate, "langchain/llm/replicate"
  end

  # Prompts are structured inputs to the LLMs. Prompts provide instructions, context and other user input that LLMs use to generate responses.
  module Prompt
    require_relative "langchain/prompt/loading"

    autoload :Base, "langchain/prompt/base"
    autoload :PromptTemplate, "langchain/prompt/prompt_template"
    autoload :FewShotPromptTemplate, "langchain/prompt/few_shot_prompt_template"
  end
end

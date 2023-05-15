# frozen_string_literal: true

require_relative "./version"
require_relative "./optional_dependency_helper"

module Agent
  autoload :Base, "agent/base"
  autoload :ChainOfThoughtAgent, "agent/chain_of_thought_agent/chain_of_thought_agent.rb"
end

module Vectorsearch
  autoload :Base, "vectorsearch/base"
  autoload :Milvus, "vectorsearch/milvus"
  autoload :Pinecone, "vectorsearch/pinecone"
  autoload :Qdrant, "vectorsearch/qdrant"
  autoload :Weaviate, "vectorsearch/weaviate"
end

module LLM
  autoload :Base, "llm/base"
  autoload :Cohere, "llm/cohere"
  autoload :OpenAI, "llm/openai"
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

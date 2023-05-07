# frozen_string_literal: true

require_relative "./version"

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

module Prompts
  require_relative "prompts/loading"

  autoload :Base, "prompts/base"
  autoload :PromptTemplate, "prompts/prompt_template"
  autoload :FewShotPromptTemplate, "prompts/few_shot_prompt_template"
end
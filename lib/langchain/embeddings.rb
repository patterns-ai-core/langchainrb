# frozen_string_literal: true

module Langchain
  module Config
    EMBEDDING_SIZES = {
      "text-embedding-ada-002": 1536,
      "text-embedding-3-large": 3072,
      "text-embedding-3-small": 1536
    }.freeze
  end
end
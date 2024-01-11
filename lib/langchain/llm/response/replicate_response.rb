# frozen_string_literal: true

module Langchain::LLM
  class ReplicateResponse < BaseResponse
    def completions
      # Response comes back as an array of strings, e.g.: ["Hi", "how ", "are ", "you?"]
      # The first array element is missing a space at the end, so we add it manually
      raw_response.output[0] += " "
      [raw_response.output.join]
    end

    def completion
      completions.first
    end

    def created_at
      Time.parse(raw_response.created_at)
    end

    def embedding
      embeddings.first
    end

    def embeddings
      [raw_response.output]
    end
  end
end

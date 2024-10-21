module Langchain
  module Evals
    module LLM
      class CosineSimilarity
        attr_reader :llm

        def initialize(llm:, prompt_template: nil)
          @llm = llm
        end

        def score(question:, answer:, expected_answer:)
          answer_ebedding = llm.embed(text: answer).embedding
          expected_answer_embedding = llm.embed(text: expected_answer).embedding

          Langchain::Utils::CosineSimilarity.new(expected_answer_embedding, answer_ebedding).calculate_similarity
        end
      end
    end
  end
end

module Langchain
  module Evals
    module LLM
      class CosineSimilarity
        attr_reader :llm

        def initialize(llm:, prompt_template: nil)
          @llm = llm
        end

        def score(question:, answer:, expected_answer:)
          question_embedding = llm.embed(text: question).embedding
          answer_ebedding = llm.embed(text: answer).embedding

          Langchain::Utils::CosineSimilarity.new(question_embedding, answer_ebedding).calculate_similarity
        end
      end
    end
  end
end

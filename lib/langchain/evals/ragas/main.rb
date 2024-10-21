# freeze_string_literal: true

module Langchain
  module Evals
    # The RAGAS (Retrieval Augmented Generative Assessment) is a framework for evaluating RAG (Retrieval Augmented Generation) pipelines.
    # Based on the following research: https://arxiv.org/pdf/2309.15217.pdf
    module Ragas
      class Main
        attr_reader :llm

        def initialize(llm:)
          @llm = llm
        end

        # Returns the RAGAS scores, e.g.:
        # {
        #   ragas_score: 0.6601257446503674,
        #   answer_relevance_score: 0.9573145866787608,
        #   context_relevance_score: 0.6666666666666666,
        #   faithfulness_score: 0.5
        # }
        #
        # @param question [String] Question
        # @param answer [String] Answer
        # @param context [String] Context
        # @return [Hash] RAGAS scores
        def score(question:, answer:, context:)
          answer_relevance_score = answer_relevance.score(question: question, answer: answer)
          context_relevance_score = context_relevance.score(question: question, context: context)
          faithfulness_score = faithfulness.score(question: question, answer: answer, context: context)

          {
            ragas_score: ragas_score(answer_relevance_score, context_relevance_score, faithfulness_score),
            answer_relevance_score: answer_relevance_score,
            context_relevance_score: context_relevance_score,
            faithfulness_score: faithfulness_score
          }
        end

        private

        # Overall RAGAS score (harmonic mean): https://github.com/explodinggradients/ragas/blob/1dd363e3e54744e67b0be85962a0258d8121500a/src/ragas/evaluation.py#L140-L143
        #
        # @param answer_relevance_score [Float] Answer Relevance score
        # @param context_relevance_score [Float] Context Relevance score
        # @param faithfulness_score [Float] Faithfulness score
        # @return [Float] RAGAS score
        def ragas_score(answer_relevance_score, context_relevance_score, faithfulness_score)
          reciprocal_sum = (1.0 / answer_relevance_score) + (1.0 / context_relevance_score) + (1.0 / faithfulness_score)
          (3 / reciprocal_sum)
        end

        # @return [Langchain::Evals::Ragas::AnswerRelevance] Class instance
        def answer_relevance
          @answer_relevance ||= Langchain::Evals::Ragas::AnswerRelevance.new(llm: llm)
        end

        # @return [Langchain::Evals::Ragas::ContextRelevance] Class instance
        def context_relevance
          @context_relevance ||= Langchain::Evals::Ragas::ContextRelevance.new(llm: llm)
        end

        # @return [Langchain::Evals::Ragas::Faithfulness] Class instance
        def faithfulness
          @faithfulness ||= Langchain::Evals::Ragas::Faithfulness.new(llm: llm)
        end
      end
    end
  end
end

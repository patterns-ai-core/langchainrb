# freeze_string_literal: true

module Langchain
  module Evals
    module Ragas
      # Semantic Similarity refers to the semantic resemblance between the generated answer and the ground truth.
      # This metric embeds both answers and returns the cosine similarity between them.
      # Spec: https://github.com/explodinggradients/ragas/blob/main/docs/concepts/metrics/available_metrics/semantic_similarity.md
      class SemanticSimilarity
        attr_reader :llm, :threshold

        # @param llm [Langchain::LLM::*] Langchain::LLM::* object
        # @param threshold [Float] Optional threshold; when set, the score is 1.0 if the similarity is at or above it and 0.0 otherwise
        def initialize(llm:, threshold: nil)
          @llm = llm
          @threshold = threshold
        end

        # @param answer [String] Answer
        # @param ground_truth [String] Ground truth (reference) answer
        # @return [Float] Semantic Similarity score
        def score(answer:, ground_truth:)
          similarity = Langchain::Utils::CosineSimilarity.new(
            generate_embedding(answer),
            generate_embedding(ground_truth)
          ).calculate_similarity

          return similarity if threshold.nil?

          (similarity >= threshold) ? 1.0 : 0.0
        end

        private

        # @param text [String] Text to generate an embedding for
        # @return [Array<Float>] Embedding
        def generate_embedding(text)
          llm.embed(text: text).embedding
        end
      end
    end
  end
end

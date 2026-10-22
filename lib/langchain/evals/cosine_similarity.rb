module Langchain
  module Evals
    class CosineSimilarity
      attr_reader :llm

      def initialize(llm:)
        @llm = llm
      end

      def score(actual_output:, expected_output:)
        vector_a = llm.embed(text: actual_output).embedding
        vector_b = llm.embed(text: expected_output).embedding

        Langchain::Utils::CosineSimilarity.new(vector_a, vector_b).calculate_similarity
      end
    end
  end
end

module Langchain
  module Evals
    class Base
      # Evaluates a dataset with multiple evaluators
      # {
      #   question: "question",
      #   answer: "answer",
      #   context: "Context"
      #   "AnswerRelevance" => Float,
      #   "ContextRelevance" => Float,
      #   "Faithfulness" => Float
      # }
      #
      # @param dataset [Array<Hash>] Dataset
      # @param evaluators [Array] Evaluators
      # @return [Array<Hash>] Scored dataset
      def self.evaluate_dataset(dataset, evaluators)
        scored_dataset = []

        dataset.each do |data|
          dataset_item_scores = {}

          evaluators.each do |evaluator|
            dataset_item_scores[evaluator.class.name.split("::").last] = evaluator.score(**data)
          end

          scored_dataset << {
            **data,
            **dataset_item_scores
          }
        end
        scored_dataset
      end
    end
  end
end

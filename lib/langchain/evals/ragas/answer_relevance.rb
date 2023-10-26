# freeze_string_literal: true

require "matrix"

module Langchain
  module Evals
    module Ragas
      # Answer Relevance refers to the idea that the generated answer should address the actual question that was provided.
      # This metric evaluates how closely the generated answer aligns with the initial question or instruction.
      class AnswerRelevance
        attr_reader :llm, :batch_size

        # @param llm [Langchain::LLM::*] Langchain::LLM::* object
        # @param batch_size [Integer] Batch size, i.e., number of generated questions to compare to the original question
        def initialize(llm:, batch_size: 3)
          @llm = llm
          @batch_size = batch_size
        end

        # @param question [String] Question
        # @param answer [String] Answer
        # @return [Float] Answer Relevance score
        def score(question:, answer:)
          generated_questions = []

          batch_size.times do |i|
            prompt = answer_relevance_prompt_template.format(
              question: question,
              answer: answer
            )
            generated_questions << llm.complete(prompt: prompt).completion
          end

          scores = generated_questions.map do |generated_question|
            calculate_similarity(original_question: question, generated_question: generated_question)
          end

          # Find the mean
          scores.sum(0.0) / scores.size
        end

        private

        # @param question_1 [String] Question 1
        # @param question_2 [String] Question 2
        # @return [Float] Dot product similarity between the two questions
        def calculate_similarity(original_question:, generated_question:)
          original_embedding = generate_embedding(original_question)
          generated_embedding = generate_embedding(generated_question)

          vector_1 = Vector.elements(original_embedding)
          vector_2 = Vector.elements(generated_embedding)
          vector_1.inner_product(vector_2)
        end

        # @param text [String] Text to generate an embedding for
        # @return [Array<Float>] Embedding
        def generate_embedding(text)
          llm.embed(text: text).embedding
        end

        # @return [PromptTemplate] PromptTemplate instance
        def answer_relevance_prompt_template
          @template ||= Langchain::Prompt.load_from_path(
            file_path: Langchain.root.join("langchain/evals/ragas/prompts/answer_relevance.yml")
          )
        end
      end
    end
  end
end

# freeze_string_literal: true

module Langchain
  module Evals
    module Ragas
      # Faithfulness refers to the idea that the answer should be grounded in the given context,
      # ensuring that the retrieved context can act as a justification for the generated answer.
      # The answer is faithful to the context if the claims that are made in the answer can be inferred from the context.
      #
      # Score calculation:
      # F = |V| / |S|
      #
      # F = Faithfulness
      # |V| = Number of statements that were supported according to the LLM
      # |S| = Total number of statements extracted.
      #
      class Faithfulness
        attr_reader :llm

        # @param llm [Langchain::LLM::*] Langchain::LLM::* object
        def initialize(llm:)
          @llm = llm
        end

        # @param question [String] Question
        # @param answer [String] Answer
        # @param context [String] Context
        # @return [Float] Faithfulness score
        def score(question:, answer:, context:)
          statements = statements_extraction(question: question, answer: answer)
          statements_count = statements
            .split("\n")
            .count

          verifications = statements_verification(statements: statements, context: context)
          verifications_count = count_verified_statements(verifications)

          (verifications_count.to_f / statements_count.to_f)
        end

        private

        def count_verified_statements(verifications)
          match = verifications.match(/Final verdict for each statement in order:\s*(.*)/)
          return 0.0 unless match # no verified statements found

          verdicts = match.captures.first
          verdicts
            .split(".")
            .count { |value| to_boolean(value.strip) }
        end

        def statements_verification(statements:, context:)
          prompt = statements_verification_prompt_template.format(
            statements: statements,
            context: context
          )
          llm.complete(prompt: prompt).completion
        end

        def statements_extraction(question:, answer:)
          prompt = statements_extraction_prompt_template.format(
            question: question,
            answer: answer
          )
          llm.complete(prompt: prompt).completion
        end

        # @return [PromptTemplate] PromptTemplate instance
        def statements_verification_prompt_template
          @template_two ||= Langchain::Prompt.load_from_path(
            file_path: Langchain.root.join("langchain/evals/ragas/prompts/faithfulness_statements_verification.yml")
          )
        end

        # @return [PromptTemplate] PromptTemplate instance
        def statements_extraction_prompt_template
          @template_one ||= Langchain::Prompt.load_from_path(
            file_path: Langchain.root.join("langchain/evals/ragas/prompts/faithfulness_statements_extraction.yml")
          )
        end

        def to_boolean(value)
          Langchain::Utils::ToBoolean.new.to_bool(value)
        end
      end
    end
  end
end

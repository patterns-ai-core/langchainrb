# freeze_string_literal: true

require "pragmatic_segmenter"

module Langchain
  module Evals
    module Ragas
      # Context Relevance refers to the idea that the retrieved context should be focused, containing as little irrelevant information as possible.
      class ContextRelevance
        attr_reader :llm

        # @param llm [Langchain::LLM::*] Langchain::LLM::* object
        def initialize(llm:)
          @llm = llm
        end

        # @param question [String] Question
        # @param context [String] Context
        # @return [Float] Context Relevance score
        def score(question:, context:)
          prompt = context_relevance_prompt_template.format(
            question: question,
            context: context
          )
          sentences = llm.complete(prompt: prompt).completion

          (sentence_count(sentences).to_f / sentence_count(context).to_f)
        end

        private

        def sentence_count(context)
          ps = PragmaticSegmenter::Segmenter.new(text: context)
          ps.segment.length
        end

        # @return [PromptTemplate] PromptTemplate instance
        def context_relevance_prompt_template
          @template ||= Langchain::Prompt.load_from_path(
            file_path: Langchain.root.join("langchain/evals/ragas/prompts/context_relevance.yml")
          )
        end
      end
    end
  end
end

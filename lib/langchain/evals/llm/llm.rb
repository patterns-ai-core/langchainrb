module Langchain
  module Evals
    module LLM
      class LLM
        attr_reader :llm, :prompt_template

        def initialize(llm:, prompt_template: nil)
          @llm = llm

          @prompt_template = if prompt_template.nil?
            Langchain::Prompt.load_from_path(
              file_path: Langchain.root.join("langchain/evals/llm/prompts/expected_answer.yml")
            )
          else
            prompt_template
          end
        end

        def score(question:, answer:, expected_answer:, **_kwargs)
          prompt = prompt_template.format(
            question: question,
            answer: answer,
            expected_answer: expected_answer
          )
          completion = llm.complete(prompt: prompt).completion

          if completion.eql?("Y")
            1.0
          else
            0.0
          end
        end
      end
    end
  end
end

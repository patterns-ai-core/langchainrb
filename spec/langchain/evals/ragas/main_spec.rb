# frozen_string_literal: true

RSpec.describe Langchain::Evals::Ragas::Main do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  subject { described_class.new(llm: llm) }

  let(:question) { "Who directed the film Oppenheimer and who stars as J. Robert Oppenheimer in the film?" }
  let(:answer) { "Christopher Nolan directed the film Openheimer. Cillian Murphy stars as J. Robert Openheimer in the film." }
  let(:context) { "Oppenheimer is a 2023 biographical thriller film written and directed by Christopher Nolan. Based on the 2005 biography American Prometheus by Kai Bird and Martin J. Sherwin, the film chronicles the life of J. Robert Oppenheimer, a theoretical physicist who was pivotal in developing the first nuclear weapons as part of the Manhattan Project, and thereby ushering in the Atomic Age. Cillian Murphy stars as Oppenheimer, with Emily Blunt as Oppenheimer's wife Katherine 'Kitty' Oppenheimer." }

  describe "#evaluate_dataset" do
    before do
      allow_any_instance_of(Langchain::Evals::Ragas::AnswerRelevance).to receive(:score).and_return(0.9573145866787608)
      allow_any_instance_of(Langchain::Evals::Ragas::ContextRelevance).to receive(:score).and_return(0.6666666666666666)
      allow_any_instance_of(Langchain::Evals::Ragas::Faithfulness).to receive(:score).and_return(0.5)
    end

    let(:dataset) { [{question: question, answer: answer, context: context}] }
    let(:evaluators) { [Langchain::Evals::Ragas::AnswerRelevance.new(llm: llm), Langchain::Evals::Ragas::ContextRelevance.new(llm: llm), Langchain::Evals::Ragas::Faithfulness.new(llm: llm)] }

    it "evaluates a dataset with multiple evaluators" do
      expect(Langchain::Evals.evaluate_dataset(dataset, evaluators)).to eq([{
        :question => question,
        :answer => answer,
        :context => context,
        "AnswerRelevance" => 0.9573145866787608,
        "ContextRelevance" => 0.6666666666666666,
        "Faithfulness" => 0.5
      }])
    end
  end

  describe "#score" do
    before do
      allow_any_instance_of(Langchain::Evals::Ragas::AnswerRelevance).to receive(:score).and_return(0.9573145866787608)
      allow_any_instance_of(Langchain::Evals::Ragas::ContextRelevance).to receive(:score).and_return(0.6666666666666666)
      allow_any_instance_of(Langchain::Evals::Ragas::Faithfulness).to receive(:score).and_return(0.5)
    end

    it "generates the scores" do
      expect(subject.score(question: question, answer: answer, context: context)).to eq({
        ragas_score: 0.6601257446503674,
        answer_relevance_score: 0.9573145866787608,
        context_relevance_score: 0.6666666666666666,
        faithfulness_score: 0.5
      })
    end
  end
end

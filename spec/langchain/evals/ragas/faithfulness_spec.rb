# frozen_string_literal: true

RSpec.describe Langchain::Evals::Ragas::Faithfulness do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  subject { described_class.new(llm: llm) }

  let(:question) { "Who directed the film Oppenheimer and who stars as J. Robert Oppenheimer in the film?" }
  let(:answer) { "Christopher Nolan directed the film Openheimer. Cillian Murphy stars as J. Robert Openheimer in the film." }
  let(:context) { "Oppenheimer is a 2023 biographical thriller film written and directed by Christopher Nolan. Based on the 2005 biography American Prometheus by Kai Bird and Martin J. Sherwin, the film chronicles the life of J. Robert Oppenheimer, a theoretical physicist who was pivotal in developing the first nuclear weapons as part of the Manhattan Project, and thereby ushering in the Atomic Age. Cillian Murphy stars as Oppenheimer, with Emily Blunt as Oppenheimer's wife Katherine 'Kitty' Oppenheimer." }

  describe "#score" do
    let(:statements) { "1. Christopher Nolan directed the film Oppenheimer.\n2. Cillian Murphy stars as J. Robert Oppenheimer in the film." }
    let(:verifications) { "1. Christopher Nolan directed the film Oppenheimer.\nExplanation: The context explicitly states that Christopher Nolan wrote and directed the film Oppenheimer. Verdict: Yes.\n2. Cillian Murphy stars as J. Robert Oppenheimer in the film.\nExplanation: The context mentions that Cillian Murphy stars in the film Oppenheimer, but it specifies that he portrays J. Robert Oppenheimer's wife Katherine 'Kitty' Oppenheimer, not J. Robert Oppenheimer himself. Verdict: No.\nFinal verdict for each statement in order: Yes. No." }

    before do
      allow(subject).to receive(:statements_extraction).and_return(statements)
      allow(subject).to receive(:statements_verification).and_return(verifications)
    end

    it "generates the faithfulness score" do
      expect(subject.score(question: question, answer: answer, context: context)).to eq(0.5)
    end
  end
end

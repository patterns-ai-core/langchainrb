RSpec.describe Langchain::Evals::LLM::CosineSimilarity do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  describe "#score" do
    subject { described_class.new(llm: llm) }

    let(:question) { "What is 2 + 2?" }
    let(:answer) { "The answer is 4" }
    let(:expected_answer) { "2 + 2 = 4" }

    before do
      allow(subject.llm).to receive(:embed).and_return(double("Langchain::LLM::OpenAIResponse", embedding: [1, 0, 0]))
    end

    it "generates the score" do
      expect(subject.score(question: question, answer: answer, expected_answer: expected_answer)).to eq(1.0)
    end
  end
end

RSpec.describe Langchain::Evals::CosineSimilarity do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  describe "#score" do
    subject { described_class.new(llm: llm) }

    let(:actual_output) { "The answer is 4" }
    let(:expected_output) { "2 + 2 = 4" }

    before do
      allow(subject.llm).to receive(:embed).and_return(double("Langchain::LLM::OpenAIResponse", embedding: [1, 0, 0]))
    end

    it "generates the score" do
      expect(subject.score(actual_output: actual_output, expected_output: expected_output)).to eq(1.0)
    end
  end
end

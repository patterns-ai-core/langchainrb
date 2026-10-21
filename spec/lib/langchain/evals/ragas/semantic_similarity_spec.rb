# frozen_string_literal: true

RSpec.describe Langchain::Evals::Ragas::SemanticSimilarity do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  subject { described_class.new(llm: llm) }

  let(:answer) { "The Eiffel Tower is located in Paris." }
  let(:ground_truth) { "The Eiffel Tower is located in Paris. It has a height of 1000ft." }

  before do
    allow(llm).to receive(:embed).with(text: answer).and_return(double(embedding: [1.0, 0.0]))
    allow(llm).to receive(:embed).with(text: ground_truth).and_return(double(embedding: [0.6, 0.8]))
  end

  describe "#score" do
    it "returns the cosine similarity between the answer and the ground truth embeddings" do
      expect(subject.score(answer: answer, ground_truth: ground_truth)).to be_within(1e-9).of(0.6)
    end

    context "with a threshold" do
      it "returns 1.0 when the similarity is at or above the threshold" do
        expect(described_class.new(llm: llm, threshold: 0.5).score(answer: answer, ground_truth: ground_truth)).to eq(1.0)
      end

      it "returns 0.0 when the similarity is below the threshold" do
        expect(described_class.new(llm: llm, threshold: 0.7).score(answer: answer, ground_truth: ground_truth)).to eq(0.0)
      end
    end
  end
end

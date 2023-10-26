# frozen_string_literal: true

RSpec.describe Langchain::Evals::Ragas::AnswerRelevance do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  subject { described_class.new(llm: llm, batch_size: 1) }

  let(:question) { "When is the scheduled launch date and time for the PSLV-C56 mission, and where will it be launched from?" }
  let(:answer) { "The scheduled launch date and time for the PSLV-C56 mission have not been provided.The PSLV-C56 mission is an important space mission for India. It aims to launch a satellite into orbit to study weather patterns." }

  describe "#score" do
    let(:score) { 0.9000376194063501 }
    let(:generated_question) { "What is the purpose of the PSLV-C56 mission?" }

    before do
      allow(subject.llm).to receive(:complete).and_return(double("Langchain::LLM::OpenAIResponse", completion: generated_question))
      allow(subject).to receive(:calculate_similarity)
        .with(original_question: question, generated_question: generated_question)
        .and_return(score)
    end

    it "generates the answer_relevance score" do
      expect(subject.score(question: question, answer: answer)).to be_a(Float)
      expect(subject.score(question: question, answer: answer)).to eq(score)
    end
  end

  describe "#calculate_similarity" do
    xit "calculates the dot product between two questions" do
    end
  end
end

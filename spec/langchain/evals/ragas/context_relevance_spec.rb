# frozen_string_literal: true

RSpec.describe Langchain::Evals::Ragas::ContextRelevance do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  subject { described_class.new(llm: llm) }

  let(:question) { "When was the Chimnabai Clock Tower completed, and who was it named after?" }
  let(:context) { "The Chimnabai Clock Tower, also known as the Raopura Tower, is a clock tower situated in the Raopura area of Vadodara, Gujarat, India. It was completed in 1896 and named in memory of Chimnabai I (1864–1885), a queen and the first wife of Sayajirao Gaekwad III of Baroda State." }

  describe "#score" do
    let(:score) { 0.9000376194063501 }
    let(:sentences) { "It was completed in 1896 and named in memory of Chimnabai I (1864–1885), a queen and the first wife of Sayajirao Gaekwad III of Baroda State." }

    before do
      allow(subject.llm).to receive(:complete).and_return(double("Langchain::LLM::OpenAIResponse", completion: sentences))
    end

    it "generates the context_relevance score" do
      expect(subject.score(question: question, context: context)).to be_a(Float)
      expect(subject.score(question: question, context: context)).to eq(0.5)
    end
  end
end

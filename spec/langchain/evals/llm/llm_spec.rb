RSpec.describe Langchain::Evals::LLM::LLM do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  describe "#score" do
    subject { described_class.new(llm: llm) }

    let(:question) { "What is 2 + 2?" }
    let(:answer) { "The answer is 4" }
    let(:expected_answer) { "2 + 2 = 4" }

    before do
      allow(subject.llm).to receive(:complete).and_return(double("Langchain::LLM::OpenAIResponse", completion: "Y"))
    end

    it "generates the score" do
      expect(subject.score(question: question, answer: answer, expected_answer: expected_answer)).to eq(1.0)
    end
  end

  context "with custom prompt template" do
    let(:prompt_template) {
      Langchain::Prompt::PromptTemplate.new(
        template: "Question: {question}. Answer: {answer}. Correct answer: {expected_answer}. Return 'Y' if answer matches correct answer, else 'N'",
        input_variables: [
          "question",
          "answer",
          "expected_answer"
        ]
      )
    }

    describe "#score" do
      subject { described_class.new(llm: llm, prompt_template: prompt_template) }

      let(:question) { "What is 2 + 2?" }
      let(:answer) { "The answer is 4" }
      let(:expected_answer) { "2 + 2 = 4" }

      before do
        allow(subject.llm).to receive(:complete).and_return(double("Langchain::LLM::OpenAIResponse", completion: "Y"))
      end

      it "generates the score" do
        expect(subject.score(question: question, answer: answer, expected_answer: expected_answer)).to eq(1.0)
      end
    end
  end
end

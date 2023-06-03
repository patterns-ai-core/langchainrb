# frozen_string_literal: true

RSpec.describe Langchain::LLM do
  describe ".build" do
    context "when llm supported" do
      it "returns an instance of the specified LLM class" do
        expect(described_class.build(:openai, "123")).to be_a(Langchain::LLM::OpenAI)
      end
    end
    context "when llm is not supported" do
      it "returns an instance of the specified LLM class" do
        expect { described_class.build(:non_existing, "123") }.to raise_error(ArgumentError)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::LLM do
  describe ".build" do
    it "returns an instance of the specified LLM class" do
      expect(described_class.build(:openai, "123")).to be_a(Langchain::LLM::OpenAI)
    end
  end
end

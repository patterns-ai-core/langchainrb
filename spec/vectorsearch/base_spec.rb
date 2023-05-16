# frozen_string_literal: true

RSpec.describe Vectorsearch::Base do
  subject { described_class.new(llm: :openai, llm_api_key: "123") }

  describe "#initialize" do
    it "correctly with llm: :cohere" do
      expect(
        described_class.new(
          llm: :cohere,
          llm_api_key: "123"
        )
        .llm_client
      ).to be_a(LLM::Cohere)
    end

    it "correctly with llm: :openai" do
      expect(
        subject.llm_client
      ).to be_a(LLM::OpenAI)
    end

    it "correctly with llm: :huggingface" do
      expect(
        described_class.new(
          llm: :huggingface,
          llm_api_key: "123"
        )
        .llm_client
      ).to be_a(LLM::HuggingFace)
    end

    it "throws an error with currently unsupported llm: :anthropic" do
      expect {
        described_class.new(
          llm: :anthropic,
          llm_api_key: "123"
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe "#generate_prompt" do
    it "produces a prompt with the correct format" do
      expect(
        subject.generate_prompt(question: "What is the meaning of life?", context: "41\n42\n43")
      ).to eq <<~PROMPT.chomp
        Context:
        41
        42
        43
        ---
        Question: What is the meaning of life?
        ---
        Answer:
      PROMPT
    end
  end
end

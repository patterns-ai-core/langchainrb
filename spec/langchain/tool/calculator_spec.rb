# frozen_string_literal: true

require "eqn"

RSpec.describe Langchain::Tool::Calculator do
  subject {
    llm = Langchain::LLM::OpenAI.new(api_key: "123")
    described_class.new(llm: llm)
  }

  describe "#execute" do
    it "calculates the result" do
      expect(subject.execute(input: "2+2")).to eq(4)
    end

    it "calls the llm when eqn throws an error" do
      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete)
          .and_return("```text\n2+2```")

      subject.execute(input: "what is 2+2?")
    end
  end

  describe "#tool_name" do
    it "returns the tool name" do
      expect(subject.tool_name).to eq("calculator")
    end
  end
end

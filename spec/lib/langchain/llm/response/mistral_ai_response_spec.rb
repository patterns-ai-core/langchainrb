# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::MistralAIResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/mistral_ai/chat.json")
  }

  describe "#chat_completion" do
    it "return chat_completion" do
      subject = described_class.new(raw_chat_completions_response)
      expect(subject.chat_completion).to eq("Hello!")
    end
  end

  describe "#tool_calls" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/mistral_ai/chat_with_tool_calls.json")
    }
    let(:response) { described_class.new(raw_response) }

    it "returns tool_calls" do
      expect(response.tool_calls).to eq(
        [
          {
            "function" => {
              "arguments" => "{\"input\": \"1+1\"}",
              "name" => "langchain_tool_calculator__execute"
            },
            "id" => "b7ndVdw4R"
          }
        ]
      )
    end
  end
end

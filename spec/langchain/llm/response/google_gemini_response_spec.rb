# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGeminiResponse do
  describe "#chat_completion" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/google_gemini/chat.json")
    }
    let(:response) { described_class.new(raw_response) }

    it "returns text" do
      expect(response.chat_completion).to eq("The answer is 4.0")
    end

    it "returns role" do
      expect(response.role).to eq("model")
    end
  end

  describe "#tool_calls" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/google_gemini/chat_with_tool_calls.json")
    }
    let(:response) { described_class.new(raw_response) }

    it "returns tool_calls" do
      expect(response.tool_calls).to eq([{"functionCall" => {"name" => "calculator__execute", "args" => {"input" => "2+2"}}}])
    end
  end
end

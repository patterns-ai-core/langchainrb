# frozen_string_literal: true

RSpec.describe Langchain::Assistant::Messages::GoogleGeminiMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_hash" do
    it "returns function" do
      message = described_class.new(role: "function", content: "4.0", tool_call_id: "calculator__execute")
      expect(message.to_hash).to eq({parts: [{functionResponse: {name: "calculator__execute", response: {content: "4.0", name: "calculator__execute"}}}], role: "function"})
    end

    it "returns all function responses in one message" do
      message = described_class.new(
        role: "function",
        content: ["first", "second"],
        tool_call_id: ["search__execute", "lookup__execute"]
      )

      expect(message.to_hash[:parts]).to eq([
        {functionResponse: {name: "search__execute", response: {content: "first", name: "search__execute"}}},
        {functionResponse: {name: "lookup__execute", response: {content: "second", name: "lookup__execute"}}}
      ])
    end

    it "returns tool_calls" do
      message = described_class.new(role: "model", tool_calls: [])
      expect(message.to_hash).to eq({parts: [{text: ""}], role: "model"})
    end
  end
end

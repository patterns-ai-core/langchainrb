# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::AwsBedrockAnthropicResponse do
  describe "#thinking_blocks" do
    it "returns the thinking and redacted_thinking blocks with symbol keys, in order" do
      response = described_class.new({
        "content" => [
          {"type" => "thinking", "thinking" => "Let me check.", "signature" => "EqQBCgIYAhIM"},
          {"type" => "redacted_thinking", "data" => "EmwKAhgBEgy3va3pzix"},
          {"type" => "text", "text" => "Done."}
        ]
      })

      expect(response.thinking_blocks).to eq([
        {type: "thinking", thinking: "Let me check.", signature: "EqQBCgIYAhIM"},
        {type: "redacted_thinking", data: "EmwKAhgBEgy3va3pzix"}
      ])
    end

    it "returns [] when the response has no content" do
      expect(described_class.new({}).thinking_blocks).to eq([])
    end
  end
end

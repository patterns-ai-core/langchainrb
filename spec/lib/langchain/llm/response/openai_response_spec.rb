# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::OpenAIResponse do
  describe "#tool_calls" do
    it "returns the tool calls when present" do
      raw = {"choices" => [{"message" => {"role" => "assistant", "tool_calls" => [{"id" => "call_1"}]}}]}

      expect(described_class.new(raw).tool_calls).to eq([{"id" => "call_1"}])
    end

    it "returns [] when the message has no tool_calls" do
      raw = {"choices" => [{"message" => {"role" => "assistant", "content" => "hi"}}]}

      expect(described_class.new(raw).tool_calls).to eq([])
    end

    it "returns [] when choices is empty" do
      expect(described_class.new({"choices" => []}).tool_calls).to eq([])
    end

    it "returns [] when there is no choices key (e.g. an error response)" do
      expect(described_class.new({"error" => {"message" => "boom"}}).tool_calls).to eq([])
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::AnthropicResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/anthropic/chat.json"), symbolize_names: true
  }

  describe "#chat_completion" do
    it "return chat_completion" do
      subject = described_class.new(raw_chat_completions_response)
      expect(subject.chat_completion).to eq("The sky doesn't have a defined height or upper limit.")
    end
  end

  describe "#tool_calls" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/anthropic/chat_with_tool_calls.json"), symbolize_names: true
    }
    let(:response) { described_class.new(raw_response) }

    it "returns tool_calls" do
      expect(response.tool_calls).to eq(
        [
          {
            type: "tool_use",
            id: "toolu_01UEciZACvRZ6S4rqAwD1syH",
            name: "news_retriever__get_everything",
            input: {
              q: "Google I/O 2024",
              sort_by: "publishedAt",
              language: "en"
            }
          }
        ]
      )
    end

    it "returns every tool_use block when the model calls tools in parallel" do
      raw_response = JSON.parse(
        File.read("spec/fixtures/llm/anthropic/chat_with_multiple_tool_calls.json"),
        symbolize_names: true
      )
      response = described_class.new(raw_response)

      expect(response.tool_calls).to eq(
        [
          {
            type: "tool_use",
            id: "toolu_01UEciZACvRZ6S4rqAwD1syH",
            name: "weather__get_current",
            input: {city: "Santo Domingo"}
          },
          {
            type: "tool_use",
            id: "toolu_02VFdjAbDwSA7T5srBxE2tzI",
            name: "weather__get_current",
            input: {city: "Toronto"}
          }
        ]
      )
    end
  end

  describe "#thinking_blocks" do
    it "returns the thinking and redacted_thinking blocks unchanged, in order" do
      thinking = {type: "thinking", thinking: "Let me check.", signature: "EqQBCgIYAhIM"}
      redacted = {type: "redacted_thinking", data: "EmwKAhgBEgy3va3pzix"}
      response = described_class.new({content: [thinking, redacted, {type: "text", text: "Done."}]})

      expect(response.thinking_blocks).to eq([thinking, redacted])
    end

    it "returns [] when the response has no thinking" do
      expect(described_class.new({content: [{type: "text", text: "Hi"}]}).thinking_blocks).to eq([])
    end
  end
end

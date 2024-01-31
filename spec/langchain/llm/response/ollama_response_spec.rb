# frozen_string_literal: true

RSpec.describe Langchain::LLM::OllamaResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/ollama/chat.json")
  }

  describe "chat completions" do
    subject { described_class.new(raw_chat_completions_response) }

    it "returns chat_completion" do
      expect(subject.chat_completion).to eq(raw_chat_completions_response.dig("message", "content"))
    end

    it "prompt_tokens returns correct value" do
      expect(subject.prompt_tokens).to eq(98)
    end

    it "completion_tokens returns correct value" do
      expect(subject.completion_tokens).to eq(90)
    end

    it "created_at returns correct value" do
      expect(subject.created_at).to eq(Time.new(raw_chat_completions_response.dig("created_at")))
    end
  end
end

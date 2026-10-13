# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::CohereResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/cohere/chat.json")
  }

  subject { described_class.new(raw_chat_completions_response) }

  describe "#chat_completion" do
    it "returns chat_completion" do
      expect(subject.chat_completion).to eq("I am an AI chatbot and do not possess emotions or feelings, so the concept of \"being\" does not apply to me in the traditional sense. However, I am functioning properly and ready to assist you with any queries or tasks you may have. How can I help you today?")
    end

    it "returns role" do
      expect(subject.role).to eq("CHATBOT")
    end
  end

  context "with a v2 Chat API response" do
    subject { described_class.new(JSON.parse(File.read("spec/fixtures/llm/cohere/chat_v2.json"))) }

    it "returns the text, role and token usage" do
      expect(subject.chat_completion).to eq("I'm doing well, thanks for asking! How can I help you today?")
      expect(subject.role).to eq("assistant")
      expect(subject.prompt_tokens).to eq(12)
      expect(subject.completion_tokens).to eq(16)
      expect(subject.tool_calls).to eq([])
    end
  end

  context "with an error body" do
    subject { described_class.new({"id" => "1", "message" => "Incorrect API key provided"}) }

    it "returns nil instead of raising" do
      expect(subject.chat_completion).to be_nil
      expect(subject.tool_calls).to eq([])
    end
  end

  context "with a v1 Chat API response" do
    it "returns the token usage" do
      expect(subject.prompt_tokens).to eq(4)
      expect(subject.completion_tokens).to eq(57)
    end
  end
end

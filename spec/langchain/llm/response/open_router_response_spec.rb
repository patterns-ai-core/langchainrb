# frozen_string_literal: true

RSpec.describe Langchain::LLM::OpenRouterResponse do
  let(:raw_chat_completions_response) {
    {
      "id" => "gen-xyz123",
      "object" => "chat.completion",
      "created" => 1710807304,
      "model" => "mistralai/mixtral-8x7b-instruct",
      "choices" => [{
        "index" => 0,
        "message" => {
          "role" => "assistant",
          "content" => "Hello! How can I help you today?"
        },
        "finish_reason" => "stop"
      }],
      "usage" => {
        "prompt_tokens" => 14,
        "total_tokens" => 61,
        "completion_tokens" => 47
      }
    }
  }

  subject { described_class.new(raw_chat_completions_response) }

  describe "#chat_completion" do
    it "returns chat completion" do
      expect(subject.chat_completion).to eq("Hello! How can I help you today?")
    end
  end

  describe "#role" do
    it "returns role" do
      expect(subject.role).to eq("assistant")
    end
  end

  describe "#model" do
    it "returns model" do
      expect(subject.model).to eq("mistralai/mixtral-8x7b-instruct")
    end
  end

  describe "#created_at" do
    it "returns created_at" do
      expect(subject.created_at).to eq(Time.at(1710807304))
    end
  end

  describe "#prompt_tokens" do
    it "returns prompt_tokens" do
      expect(subject.prompt_tokens).to eq(14)
    end
  end

  describe "#completion_tokens" do
    it "returns completion_tokens" do
      expect(subject.completion_tokens).to eq(47)
    end
  end

  describe "#total_tokens" do
    it "returns total_tokens" do
      expect(subject.total_tokens).to eq(61)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::LLM::GooglePalmResponse do
  let(:raw_embedding_response) {
    JSON.parse File.read("spec/fixtures/llm/google_palm/embed.json")
  }

  let(:raw_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/google_palm/complete.json")
  }

  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/google_palm/chat.json")
  }

  describe "embeddings" do
    subject { described_class.new(raw_embedding_response) }

    it "returns embeddings" do
      expect(subject.embeddings).to eq([[
        -0.02496011,
        0.0151393665,
        0.02246684
      ]])
    end

    it "#returns embedding" do
      expect(subject.embedding).to eq([
        -0.02496011,
        0.0151393665,
        0.02246684
      ])
    end
  end

  describe "completions" do
    subject { described_class.new(raw_completions_response) }

    it "returns completions" do
      expect(subject.completions).to eq(raw_completions_response.dig("candidates"))
    end

    it "returns completion" do
      expect(subject.completion).to eq("A man walks into a library and asks for books about paranoia. The librarian whispers, \"They're right behind you!\"")
    end
  end

  describe "chat completions" do
    subject { described_class.new(raw_chat_completions_response) }

    it "returns chat_completions" do
      expect(subject.chat_completions).to eq(raw_chat_completions_response.dig("candidates"))
    end

    it "returns chat_completion" do
      expect(subject.chat_completion).to eq("I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?")
    end
  end
end

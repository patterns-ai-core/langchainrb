# frozen_string_literal: true

require "faraday"

RSpec.describe Langchain::LLM::Ollama do
  let(:subject) { described_class.new(url: "http://localhost:11434", default_options: {completion_model: "llama2", embeddings_model: "llama2"}) }

  describe "#initialize" do
    it "initializes the client without any errors" do
      expect { subject }.not_to raise_error
    end
  end

  describe "#embed" do
    let(:response_body) {
      {"embedding" => [0.1, 0.2, 0.3]}
    }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(double(body: response_body))
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello, world!")).to be_a(Langchain::LLM::OllamaResponse)
      expect(subject.embed(text: "Hello, world!").embedding.count).to eq(3)
    end
  end

  describe "#complete" do
    it "returns a completion" do
      VCR.use_cassette("ollama-completion") do
        response = subject.complete(prompt: "In one word, life is ")

        expect(response).to be_a(Langchain::LLM::OllamaResponse)
        expect(response.completion).to eq("\nIn one word, life is... complex.")
      end
    end
  end

  describe "#chat" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/llm/ollama/chat.json")) }
    let(:messages) {
      [
        {role: "user", content: "Hey! How are you?"},
        {role: "assistant", content: " I'm just an AI, I don't have feelings or emotions, so I can't feel well or poorly. However, I'm here to help you with any questions or tasks you may have! Is there something specific you would like me to assist you with?"},
        {role: "user", content: "Please help me debug my computer!"}
      ]
    }

    it "returns a chat completion" do
      allow(subject.send(:client)).to receive(:post).with("api/chat").and_return(double(body: fixture))
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::OllamaResponse)
      expect(response.chat_completion).to eq(fixture.dig("message", "content"))
    end
  end

  describe "#summarize" do
    let(:mary_had_a_little_lamb_text) {
      File.read("spec/fixtures/llm/ollama/mary_had_a_little_lamb.txt")
    }

    it "returns a chat completion" do
      VCR.use_cassette("ollama-summarize") do
        response = subject.summarize(text: mary_had_a_little_lamb_text)

        expect(response).to be_a(Langchain::LLM::OllamaResponse)
        expect(response.summarization).not_to match(/summary/)
        expect(response.summarization).to start_with("Mary has a little lamb that follows")
      end
    end
  end

  describe "#default_dimension" do
    let(:response_body) {
      {"embedding" => 1_024.times.map { rand }}
    }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(double(body: response_body))
    end

    it "returns size of embeddings" do
      expect(subject.default_dimension).to eq(1_024)
    end
  end
end

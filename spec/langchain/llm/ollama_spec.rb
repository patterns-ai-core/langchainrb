# frozen_string_literal: true

require "faraday"

RSpec.describe Langchain::LLM::Ollama do
  let(:subject) { described_class.new(url: "http://localhost:11434", default_options: {completion_model_name: "llama3.1", embeddings_model_name: "llama3.1"}) }
  let(:client) { subject.send(:client) }

  describe "#initialize" do
    it "initializes the client without any errors" do
      expect { subject }.not_to raise_error
    end

    it "initialize with default arguments" do
      expect { described_class.new }.not_to raise_error
      expect(described_class.new.url).to eq("http://localhost:11434")
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
    let(:prompt) { "In one word, life is " }
    let(:response) { subject.complete(prompt: prompt) }

    it "returns a completion", :vcr do
      expect(response).to be_a(Langchain::LLM::OllamaResponse)
      expect(response.completion).to eq("fragile.")
    end

    it "does not use streamed responses", vcr: {cassette_name: "Langchain_LLM_Ollama_complete_returns_a_completion"} do
      expect(client).to receive(:post).with("api/generate", hash_including(stream: false)).and_call_original
      response
    end

    context "when passing a block" do
      let(:response) { subject.complete(prompt: prompt) { |resp| streamed_responses << resp } }
      let(:streamed_responses) { [] }

      it "returns a completion", :vcr do
        expect(response).to be_a(Langchain::LLM::OllamaResponse)
        expect(response.completion).to eq("unpredictable.")
        expect(response.total_tokens).to eq(22)
      end

      it "uses streamed responses", vcr: {cassette_name: "Langchain_LLM_Ollama_complete_when_passing_a_block_returns_a_completion"} do
        expect(client).to receive(:post).with("api/generate", hash_including(stream: true)).and_call_original
        response
      end

      it "yields the intermediate responses to the block", vcr: {cassette_name: "Langchain_LLM_Ollama_complete_when_passing_a_block_returns_a_completion"} do
        response
        expect(streamed_responses.length).to eq 5
        expect(streamed_responses).to be_all { |resp| resp.is_a?(Langchain::LLM::OllamaResponse) }
        expect(streamed_responses.map(&:completion).join).to eq("unpredictable.")
      end
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", content: "Hey! How are you?"}] }
    let(:response) { subject.chat(messages: messages) }

    it "returns a chat completion", :vcr do
      expect(response).to be_a(Langchain::LLM::OllamaResponse)
      expect(response.chat_completion).to include("I'm just an AI")
    end

    it "does not use streamed responses", vcr: {cassette_name: "Langchain_LLM_Ollama_chat_returns_a_chat_completion"} do
      expect(client).to receive(:post).with("api/chat", hash_including(stream: false)).and_call_original
      response
    end

    context "when passing a block" do
      let(:response) { subject.chat(messages: messages) { |resp| streamed_responses << resp } }
      let(:streamed_responses) { [] }

      it "returns a chat completion", :vcr do
        expect(response).to be_a(Langchain::LLM::OllamaResponse)
        expect(response.chat_completion).to include("I'm just a language model")
      end

      it "uses streamed responses", vcr: {cassette_name: "Langchain_LLM_Ollama_chat_when_passing_a_block_returns_a_chat_completion"} do
        expect(client).to receive(:post).with("api/chat", hash_including(stream: true)).and_call_original
        response
      end

      it "yields the intermediate responses to the block", vcr: {cassette_name: "Langchain_LLM_Ollama_chat_when_passing_a_block_returns_a_chat_completion"} do
        response
        expect(streamed_responses.length).to eq 42
        expect(streamed_responses).to be_all { |resp| resp.is_a?(Langchain::LLM::OllamaResponse) }
        expect(streamed_responses.map(&:chat_completion).join).to include("I'm just a language model")
      end
    end
  end

  describe "#summarize" do
    let(:mary_had_a_little_lamb_text) {
      File.read("spec/fixtures/llm/ollama/mary_had_a_little_lamb.txt")
    }

    it "returns a summarization", :vcr do
      response = subject.summarize(text: mary_had_a_little_lamb_text)

      expect(response).to be_a(Langchain::LLM::OllamaResponse)
      expect(response.completion).not_to match(/summary/)
      expect(response.completion).to start_with("A little lamb follows Mary everywhere she goes")
    end
  end

  describe "#default_dimensions" do
    it "returns size of llama3 embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "llama3.1"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of llava embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "llava"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mistral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "mistral"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mixtral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "mixtral"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of dolphin-mixtral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "dolphin-mixtral"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mistral-openorca embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "mistral-openorca"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of codellama embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "codellama"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    # this one has not been hardcoded, but will be looked up
    # by generating an embedding and checking its size
    it "returns size of tinydolphin embeddings", vcr: true do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embeddings_model_name: "tinydolphin"})

      expect(subject.default_dimensions).to eq(2_048)
    end
  end
end

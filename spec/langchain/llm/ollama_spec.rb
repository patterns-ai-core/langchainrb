# frozen_string_literal: true

require "faraday"

RSpec.describe Langchain::LLM::Ollama do
  let(:subject) { described_class.new(url: "http://localhost:11434", default_options: {completion_model: "llama3.1", embedding_model: "llama3.1"}) }
  let(:client) { subject.send(:client) }

  describe "#initialize" do
    it "initializes the client without any errors" do
      expect { subject }.not_to raise_error
    end

    it "initialize with default arguments" do
      expect { described_class.new }.not_to raise_error
      expect(described_class.new.url).to eq("http://localhost:11434")
    end

    it "sets auth headers if api_key is passed" do
      subject = described_class.new(url: "http://localhost)", api_key: "abc123")

      expect(subject.send(:client).headers).to include("Authorization" => "Bearer abc123")
    end

    context "when default_options are passed" do
      let(:default_options) { {response_format: "json"} }
      let(:messages) { [{role: "user", content: "Return data from the following sentence: John is a 30 year old software engineering living in SF."}] }
      let(:response) { subject.chat(messages: messages) { |resp| streamed_responses << resp } }
      let(:streamed_responses) { [] }

      subject { described_class.new(default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:response_format]).to eq("json")
      end

      it "get passed to consecutive chat() call", vcr: {cassette_name: "Langchain_LLM_Ollama_chat_returns_a_chat_completion_format_json"} do
        expect(client).to receive(:post).with("api/chat", hash_including(format: "json")).and_call_original
        expect(JSON.parse(response.chat_completion)).to eq({"Name" => "John", "Age" => 30, "Profession" => "Software Engineering", "Location" => "SF"})
      end
    end
  end

  describe "#embed" do
    let(:response_body) {
      {"embeddings" => [[0.1, 0.2, 0.3]]}
    }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(double(body: response_body))
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello, world!")).to be_a(Langchain::LLM::OllamaResponse)
      expect(subject.embed(text: "Hello, world!").embedding.count).to eq(3)
    end

    it "sends an input array to the client" do
      subject.embed(text: "Hello, world!")

      expect(client).to have_received(:post) do |path, &block|
        req = double("request").as_null_object
        block.call(req)
        expect(req).to have_received(:body=).with(hash_including(input: ["Hello, world!"]))
      end
    end

    context "when the JSON response contains no embeddings" do
      let(:response_body) {
        {"embeddings" => []}
      }

      it "#embedding returns nil" do
        expect(subject.embed(text: "Hello, world!").embedding).to be nil
      end
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
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "llama3.1"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of llava embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "llava"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mistral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "mistral"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mixtral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "mixtral"})

      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of dolphin-mixtral embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "dolphin-mixtral"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of mistral-openorca embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "mistral-openorca"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    it "returns size of codellama embeddings" do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "codellama"})
      expect(subject.default_dimensions).to eq(4_096)
    end

    # this one has not been hardcoded, but will be looked up
    # by generating an embedding and checking its size
    it "returns size of tinydolphin embeddings", vcr: true do
      subject = described_class.new(url: "http://localhost:11434", default_options: {embedding_model: "tinydolphin"})

      expect(subject.default_dimensions).to eq(2_048)
    end
  end
end

# frozen_string_literal: true

require "faraday"

RSpec.describe Langchain::LLM::Ollama do
  let(:subject) { described_class.new(url: "http://localhost:11434") }

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

  xdescribe "#complete" do
  end
end

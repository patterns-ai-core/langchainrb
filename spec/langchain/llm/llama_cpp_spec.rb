# frozen_string_literal: true

require "llama_cpp"

RSpec.describe Langchain::LLM::LlamaCpp do
  subject { described_class.new(model_path: "./", seed: 1) }

  let(:llama_context) { double("LLaMACpp::Context") }
  let(:llama_model) { double("LLaMACpp::Model") }
  let(:llama_context_params) { double("LLaMACpp::ContextParams") }

  before do
    allow(LLaMACpp::Model).to receive(:new).and_return(llama_model)
    allow(LLaMACpp::Context).to receive(:new).and_return(llama_context)
  end

  describe "#embed" do
    let(:embedding) { [0.1, 0.2, 0.3] }

    before do
      allow(llama_model).to receive(:tokenize).and_return([1, 9029])
      allow(llama_model).to receive(:desc).and_return("test")
      allow(llama_context).to receive(:model).and_return(llama_model)
      allow(llama_context).to receive(:eval)
      allow(llama_context).to receive(:embeddings).and_return(embedding)
    end

    it "generates an embedding" do
      expect(subject.embed(text: "Hello World").embedding).to eq(embedding)
    end
  end

  describe "#complete" do
    let(:completion) { "I'm doing well. How about you?" }

    before do
      allow(LLaMACpp).to receive(:generate).and_return(completion)
    end

    it "generates a completion" do
      expect(subject.complete(prompt: "Hello! How are you?")).to eq(completion)
    end
  end
end

# frozen_string_literal: true

require "replicate"

RSpec.describe Langchain::LLM::Replicate do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#completion_model" do
    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(
        Replicate::Record::ModelVersion.new({}, {})
      )
    end

    it "returns the model" do
      expect(subject.send(:completion_model)).to be_a(Replicate::Record::ModelVersion)
    end
  end

  describe "#embeddings_model" do
    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(
        Replicate::Record::ModelVersion.new({}, {})
      )
    end

    it "returns the model" do
      expect(subject.send(:embeddings_model)).to be_a(Replicate::Record::ModelVersion)
    end
  end

  describe "#complete" do
    let(:model) { Replicate::Record::ModelVersion.new({}, {}) }
    let(:prompt) { "Hello World" }
    let(:output) { ["Foo", "bar ", "!"] }

    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(model)
      allow(model).to receive(:predict).with(prompt: prompt).and_return(
        double(finished?: true, output: output)
      )
    end

    it "returns an embedding" do
      expect(subject.complete(prompt: prompt)).to eq("Foo bar !")
    end
  end

  describe "#embed" do
    let(:model) { Replicate::Record::ModelVersion.new({}, {}) }
    let(:embedding) { [0.1, 0.2, 0.3] }
    let(:text) { "Hello World" }

    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(model)
      allow(model).to receive(:predict).with(input: text).and_return(
        double(finished?: true, output: embedding)
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: text)).to eq(embedding)
    end
  end
end

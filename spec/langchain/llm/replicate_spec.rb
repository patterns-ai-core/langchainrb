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
      expect(subject.complete(prompt: prompt).completion).to eq("Foo bar !")
    end

    context "with custom default_options" do
      let(:subject) {
        described_class.new(
          api_key: "123",
          default_options: {completion_model_name: "replicate/vicuna-foobar"}
        )
      }

      it "passes correct options to the completions method" do
        latest_version_stub = double("latest_version")
        expect(latest_version_stub).to receive(:latest_version).and_return(model)

        expect(subject.client).to receive(:retrieve_model).with(
          "replicate/vicuna-foobar"
        ).and_return(latest_version_stub)

        subject.complete(prompt: "Hello World")
      end
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
      expect(subject.embed(text: text).embedding).to eq(embedding)
    end
  end

  describe "#summarize" do
    let(:text) { "Text to summarize" }

    before do
      allow(subject).to receive(:complete).and_return("Summary")
    end

    it "returns a summary" do
      expect(subject.summarize(text: text)).to eq("Summary")
    end
  end
end

# frozen_string_literal: true

require "replicate"

RSpec.describe LLM::Replicate do
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

  describe "#embed" do
    let(:embeddings_model) { Replicate::Record::ModelVersion.new({}, {}) }
    let(:embedding) { [0.1, 0.2, 0.3] }

    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(embeddings_model)
      allow(embeddings_model).to predict(input: text).and_return(
        double(finished?: true, output: embedding)
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello World")).to eq(embedding)
    end
  end
end

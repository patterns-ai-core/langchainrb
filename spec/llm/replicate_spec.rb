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
      expect(subject.completion_model).to be_a(Replicate::Record::ModelVersion)
    end
  end

  describe "#embeddings_model" do
    before do
      allow(subject.client).to receive_message_chain(:retrieve_model, :latest_version).and_return(
        Replicate::Record::ModelVersion.new({}, {})
      )
    end

    it "returns the model" do
      expect(subject.embeddings_model).to be_a(Replicate::Record::ModelVersion)
    end
  end
end

# frozen_string_literal: true

require "hugging_face"

RSpec.describe Langchain::LLM::HuggingFace do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    before do
      allow(subject.client).to receive(:embedding).and_return(
        [-1.5693359, -0.9458008, 1.9355469]
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello World").embedding).to eq([-1.5693359, -0.9458008, 1.9355469])
    end

    context "when the embeddings_model_name is passed as an argument" do
      let(:subject) {
        described_class.new(
          api_key: "123",
          default_options: {
            embeddings_model_name: "mixedbread-ai/mxbai-embed-large-v1",
            dimensions: 1_024
          }
        )
      }

      it "returns an embedding" do
        expect(subject.embed(text: "Hello World").embedding).to eq([-1.5693359, -0.9458008, 1.9355469])
      end
    end
  end

  describe "#default_dimensions" do
    it "returns the default dimensions" do
      expect(subject.default_dimensions).to eq(384)
    end
  end

  describe "#default_dimensions" do
    it "returns the default dimensions" do
      expect(subject.default_dimensions).to eq(384)
    end

    context "when the dimensions is passed as an argument" do
      let(:subject) do
        described_class.new(api_key: "123", default_options: {
          embeddings_model_name: "mixedbread-ai/mxbai-embed-large-v1",
          dimensions: 1_024
        })
      end

      it "sets the default_dimensions" do
        expect(subject.default_dimensions).to eq 1_024
      end
    end
  end
end

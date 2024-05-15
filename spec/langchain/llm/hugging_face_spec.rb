# frozen_string_literal: true

require "hugging_face"

RSpec.describe Langchain::LLM::HuggingFace do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    context "when the embeddings_model_name is not passed as an argument" do
      let(:embedding) {
        [-0.03447720780968666, 0.031023189425468445, 0.006734968163073063]
      }

      before do
        allow(subject.client).to receive(:embedding).and_return(embedding)
      end

      it "returns an embedding" do
        expect(subject.embed(text: "Hello World").embedding).to eq(embedding)
      end
    end

    context "when the embeddings_model_name is passed as an argument" do
      let(:embedding) {
        [0.3980584144592285, 0.5542294979095459, 0.28632670640945435]
      }

      before do
        allow(subject.client).to receive(:embedding).and_return(embedding)
      end

      let(:subject) {
        described_class.new(
          api_key: "123",
          default_options: {
            embeddings_model_name: "mixedbread-ai/mxbai-embed-large-v1"
          }
        )
      }

      it "returns an embedding" do
        expect(subject.embed(text: "Hello World").embedding).to eq(embedding)
      end
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

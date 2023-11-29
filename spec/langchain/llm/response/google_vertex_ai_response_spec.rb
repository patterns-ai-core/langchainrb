# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleVertexAiResponse do
  let(:raw_embedding_response) { JSON.parse(File.read("spec/fixtures/llm/google_vertex_ai/embed.json"), symbolize_names: true) }

  describe "embeddings" do
    subject { described_class.new(raw_embedding_response) }

    it "returns embeddings" do
      expect(subject.embeddings).to eq([[
        -0.00879860669374466,
        0.007578692398965359,
        0.021136576309800148
      ]])
    end

    it "#returns embedding" do
      expect(subject.embedding).to eq([
        -0.00879860669374466,
        0.007578692398965359,
        0.021136576309800148
      ])
    end

    it "#return total_tokens" do
      expect(subject.total_tokens).to eq(3)
    end
  end
end

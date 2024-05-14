# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGeminiResponse do
  describe "#chat_completion" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/google_gemini/chat.json")
    }
    let(:response) { described_class.new(raw_response) }

    it "returns text" do
      expect(response.chat_completion).to eq("The answer is 4.0")
    end

    it "returns role" do
      expect(response.role).to eq("model")
    end
  end

  describe "#tool_calls" do
    let(:raw_response) {
      JSON.parse File.read("spec/fixtures/llm/google_gemini/chat_with_tool_calls.json")
    }
    let(:response) { described_class.new(raw_response) }

    it "returns tool_calls" do
      expect(response.tool_calls).to eq([{"functionCall" => {"name" => "calculator__execute", "args" => {"input" => "2+2"}}}])
    end
  end

  describe "#embeddings" do
    let(:raw_embedding_response) { JSON.parse(File.read("spec/fixtures/llm/google_vertex_ai/embed.json")) }

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
  end
end

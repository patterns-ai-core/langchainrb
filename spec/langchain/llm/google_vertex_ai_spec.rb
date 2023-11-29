# frozen_string_literal: true

require "google-apis-aiplatform_v1"

RSpec.describe Langchain::LLM::GoogleVertexAi do
  let(:subject) { described_class.new(project_id: "123") }

  describe "#embed" do
    let(:embedding) { [-0.00879860669374466, 0.007578692398965359, 0.021136576309800148] }
    let(:raw_embedding_response) { JSON.parse(File.read("spec/fixtures/llm/google_vertex_ai/embed.json"), symbolize_names: true) }

    before do
      allow(subject.client).to receive(:predict_project_location_publisher_model).and_return(
        double("Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictResponse", to_h: raw_embedding_response)
      )
    end

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello world")

      expect(response).to be_a(Langchain::LLM::GoogleVertexAiResponse)
      expect(response.model).to eq("textembedding-gecko")
      expect(response.embedding).to eq(embedding)
      expect(response.total_tokens).to eq(3)
    end
  end
end

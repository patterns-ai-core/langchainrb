# frozen_string_literal: true

require "googleauth"

RSpec.describe Langchain::LLM::GoogleVertexAI do
  let(:subject) { described_class.new(project_id: "123", region: "us-central1") }

  describe "#embed" do
    let(:embedding) { [-0.00879860669374466, 0.007578692398965359, 0.021136576309800148] }
    let(:raw_embedding_response) { double(body: File.read("spec/fixtures/llm/google_vertex_ai/embed.json")) }

    before do
      allow(Google::Auth).to receive(:get_application_default).and_return(
        double("Google::Auth::UserRefreshCredentials", fetch_access_token!: {access_token: 123})
      )

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_embedding_response)
    end

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello world")

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("textembedding-gecko")
      expect(response.embedding).to eq(embedding)
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", parts: [{text: "How high is the sky?"}]}] }
    let(:raw_chat_completions_response) { double(body: File.read("spec/fixtures/llm/google_vertex_ai/chat.json")) }

    before do
      allow(Google::Auth).to receive(:get_application_default).and_return(
        double("Google::Auth::UserRefreshCredentials", fetch_access_token!: {access_token: 123})
      )

      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_chat_completions_response)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("gemini-1.0-pro")
      expect(response.chat_completion).to eq("The sky is not a physical object with a defined height.")
    end
  end
end

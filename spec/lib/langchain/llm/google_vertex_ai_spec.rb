# frozen_string_literal: true

require "googleauth"

RSpec.describe Langchain::LLM::GoogleVertexAI do
  subject { described_class.new(project_id: "123", region: "us-central1") }

  before do
    allow(Google::Auth).to receive(:get_application_default).and_return(
      double("Google::Auth::UserRefreshCredentials", fetch_access_token!: {access_token: 123})
    )
  end

  describe "#initialize" do
    it "initializes with default options" do
      expect(subject.defaults[:chat_model]).to eq("gemini-1.0-pro")
      expect(subject.defaults[:embedding_model]).to eq("textembedding-gecko")
      expect(subject.defaults[:temperature]).to eq(0.1)
    end

    it "merges default options with provided options" do
      default_options = {
        chat_model: "custom-model",
        temperature: 2.0,
        safety_settings: [
          {category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE"}
        ]
      }
      subject = described_class.new(project_id: "123", region: "us-central1", default_options: default_options)
      expect(subject.defaults[:chat_model]).to eq("custom-model")
      expect(subject.defaults[:temperature]).to eq(2.0)
      expect(subject.defaults[:safety_settings]).to eq(default_options[:safety_settings])
    end
  end

  describe "#embed" do
    let(:embedding) { [-0.00879860669374466, 0.007578692398965359, 0.021136576309800148] }
    let(:raw_embedding_response) { double(body: File.read("spec/fixtures/llm/google_vertex_ai/embed.json")) }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_embedding_response)
    end

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello world")

      expect(response).to be_a(Langchain::LLM::Response::GoogleGeminiResponse)
      expect(response.model).to eq("textembedding-gecko")
      expect(response.embedding).to eq(embedding)
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", parts: [{text: "How high is the sky?"}]}] }
    let(:raw_chat_completions_response) { double(body: File.read("spec/fixtures/llm/google_vertex_ai/chat.json")) }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_chat_completions_response)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::Response::GoogleGeminiResponse)
      expect(response.model).to eq("gemini-1.0-pro")
      expect(response.chat_completion).to eq("The sky is not a physical object with a defined height.")
    end

    it "uses default options if provided" do
      default_options = {
        safety_settings: [
          {category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE"},
          {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE"}
        ]
      }
      subject = described_class.new(project_id: "123", region: "us-central1", default_options: default_options)
      allow(subject).to receive(:http_post).with(any_args, hash_including(default_options)).and_call_original
      subject.chat(messages: messages)
    end
  end
end

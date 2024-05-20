# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGemini do
  let(:subject) { described_class.new(api_key: ENV["GEMINI_API_KEY"]) }

  describe "#embed" do
    let(:embedding) { [0.013168523, -0.008711934, -0.046782676] }
    let(:raw_embedding_response) { double(body: File.read("spec/fixtures/llm/google_gemini/embed.json")) }

    before do
      allow(Net::HTTP).to receive(:start).and_return(raw_embedding_response)
    end

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello world")

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("text-embedding-004")
      expect(response.embedding).to eq(embedding)
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", parts: [{text: "How high is the sky?"}]}] }
    let(:raw_chat_completions_response) { double(body: File.read("spec/fixtures/llm/google_gemini/chat.json")) }

    before do
      allow(Net::HTTP).to receive(:start).and_return(raw_chat_completions_response)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("gemini-1.5-pro-latest")
      expect(response.chat_completion).to eq("The answer is 4.0")
    end
  end
end

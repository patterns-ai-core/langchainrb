# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGemini do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#initialize" do
    it "initializes with default options" do
      expect(subject.api_key).to eq("123")
      expect(subject.defaults[:chat_completion_model_name]).to eq("gemini-1.5-pro-latest")
      expect(subject.defaults[:embeddings_model_name]).to eq("text-embedding-004")
      expect(subject.defaults[:temperature]).to eq(0.0)
    end

    it "merges default options with provided options" do
      custom_options = {chat_completion_model_name: "custom-model", temperature: 2.0}
      google_gemini_with_custom_options = described_class.new(api_key: "123", default_options: custom_options)
      expect(google_gemini_with_custom_options.defaults[:chat_completion_model_name]).to eq("custom-model")
      expect(google_gemini_with_custom_options.defaults[:temperature]).to eq(2.0)
    end
  end

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
    let(:params) { {messages: messages, model: "gemini-1.5-pro-latest", system: "system instruction", tool_choice: "AUTO", tools: [{name: "tool1"}], temperature: 1.1, response_format: "application/json", stop: ["A", "B"], generation_config: {temperature: 1.7, top_p: 1.3, response_schema: {"type" => "object", "description" => "sample schema"}}, safety_settings: [{category: "HARM_CATEGORY_UNSPECIFIED", threshold: "BLOCK_ONLY_HIGH"}]} }

    before do
      allow(Net::HTTP).to receive(:start).and_return(raw_chat_completions_response)
    end

    it "raises an error if messages are not provided" do
      expect { subject.chat({}) }.to raise_error(ArgumentError, "messages argument is required")
    end

    it "correctly processes and sends parameters" do
      expect(Net::HTTP::Post).to receive(:new) do |uri|
        expect(uri.to_s).to include("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=123")
      end.and_call_original

      allow_any_instance_of(Net::HTTP::Post).to receive(:body=) do |request, body|
        parsed_body = JSON.parse(body)

        expect(parsed_body["model"]).to eq("gemini-1.5-pro-latest")
        expect(parsed_body["contents"]).to eq([{"parts" => [{"text" => "How high is the sky?"}], "role" => "user"}])
        expect(parsed_body["systemInstruction"]).to eq({"parts" => [{"text" => "system instruction"}]})
        expect(parsed_body["toolConfig"]).to eq({"functionCallingConfig" => {"mode" => "AUTO"}})
        expect(parsed_body["tools"]).to eq({"functionDeclarations" => [{"name" => "tool1"}]})
        expect(parsed_body["temperature"]).to eq(nil)
        expect(parsed_body["generationConfig"]["temperature"]).to eq(1.7)
        expect(parsed_body["topP"]).to eq(nil)
        expect(parsed_body["generationConfig"]["topP"]).to eq(1.3)
        expect(parsed_body["responseFormat"]).to eq(nil)
        expect(parsed_body["generationConfig"]["responseMimeType"]).to eq("application/json")
        expect(parsed_body["generationConfig"]["responseSchema"]).to eq({"type" => "object", "description" => "sample schema"})
        expect(parsed_body["safetySettings"]).to eq([{"category" => "HARM_CATEGORY_UNSPECIFIED", "threshold" => "BLOCK_ONLY_HIGH"}])
      end

      subject.chat(params)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("gemini-1.5-pro-latest")
      expect(response.chat_completion).to eq("The answer is 4.0")
    end
  end
end

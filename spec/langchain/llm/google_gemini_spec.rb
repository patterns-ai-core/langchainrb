# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGemini do
  subject { described_class.new(api_key: "123") }

  describe "#initialize" do
    it "initializes with default options" do
      expect(subject.api_key).to eq("123")
      expect(subject.defaults[:chat_model]).to eq("gemini-1.5-pro-latest")
      expect(subject.defaults[:embed_model]).to eq("text-embedding-004")
      expect(subject.defaults[:temperature]).to eq(0.0)
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
      subject = described_class.new(api_key: "123", default_options: default_options)
      expect(subject.defaults[:chat_model]).to eq("custom-model")
      expect(subject.defaults[:temperature]).to eq(2.0)
      expect(subject.defaults[:safety_settings]).to eq(default_options[:safety_settings])
    end
  end

  describe "#embed" do
    let(:embedding) { [0.013168523, -0.008711934, -0.046782676] }
    let(:raw_embedding_response) { double(body: File.read("spec/fixtures/llm/google_gemini/embed.json")) }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_embedding_response)
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
    let(:params) { {messages: messages, model: "gemini-1.5-pro-latest", system: "system instruction", tool_choice: {function_calling_config: {mode: "AUTO"}}, tools: [{name: "tool1"}], temperature: 1.1, response_format: "application/json", stop: ["A", "B"], generation_config: {temperature: 1.7, top_p: 1.3, response_schema: {"type" => "object", "description" => "sample schema"}}, safety_settings: [{category: "HARM_CATEGORY_UNSPECIFIED", threshold: "BLOCK_ONLY_HIGH"}]} }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(raw_chat_completions_response)
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
        expect(parsed_body["system_instruction"]).to eq({"parts" => [{"text" => "system instruction"}]})
        expect(parsed_body["tool_config"]).to eq({"function_calling_config" => {"mode" => "AUTO"}})
        expect(parsed_body["tools"]).to eq({"function_declarations" => [{"name" => "tool1"}]})
        expect(parsed_body["temperature"]).to eq(nil)
        expect(parsed_body["generation_config"]["temperature"]).to eq(1.7)
        expect(parsed_body["top_p"]).to eq(nil)
        expect(parsed_body["generation_config"]["top_p"]).to eq(1.3)
        expect(parsed_body["response_format"]).to eq(nil)
        expect(parsed_body["generation_config"]["response_mime_type"]).to eq("application/json")
        expect(parsed_body["generation_config"]["response_schema"]).to eq({"type" => "object", "description" => "sample schema"})
        expect(parsed_body["safety_settings"]).to eq([{"category" => "HARM_CATEGORY_UNSPECIFIED", "threshold" => "BLOCK_ONLY_HIGH"}])
      end

      subject.chat(params)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: messages)

      expect(response).to be_a(Langchain::LLM::GoogleGeminiResponse)
      expect(response.model).to eq("gemini-1.5-pro-latest")
      expect(response.chat_completion).to eq("The answer is 4.0")
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
      subject = described_class.new(api_key: "123", default_options: default_options)
      allow(subject).to receive(:http_post).with(any_args, hash_including(default_options)).and_call_original
      subject.chat(messages: messages)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::LLM::GoogleGemini do
  let(:subject) { described_class.new(api_key: "XYZ") }

  describe "#generate_image" do
    let(:prompt) { "Generate a minimalistic landscape" }
    let(:model_id) { "gemini-2.0-flash-preview-image-generation" }
    let(:uri) { URI("https://generativelanguage.googleapis.com/v1beta/models/#{model_id}:generateContent?key=XYZ") }
    let(:params) do
      {
        contents: [{parts: [{text: prompt}]}],
        generationConfig: {responseModalities: ["IMAGE"], candidateCount: 1}
      }
    end
    let(:api_response) do
      {"candidates" => [{"content" => {"parts" => [{"inline_data" => {"data" => "BASE64STRING"}}]}}]}
    end

    before do
      http_response = double("response", body: api_response.to_json)
      http = double("http")
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:set_debug_output)
      allow(http).to receive(:request).and_return(http_response)
      allow(Net::HTTP).to receive(:new).and_return(http)
    end

    it "returns a response wrapper" do
      resp = subject.generate_image(prompt: prompt)
      expect(resp).to be_a(Langchain::LLM::Response::GoogleGeminiResponse)
    end
  end
end 
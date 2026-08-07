# frozen_string_literal: true

require "googleauth"
require_relative "#{Langchain.root}/langchain/llm/response/google_vertex_ai_response"

RSpec.describe Langchain::LLM::GoogleVertexAI do
  let(:subject) { described_class.new(project_id: "proj", region: "us-central1") }

  before do
    allow(Google::Auth).to receive(:get_application_default).and_return(
      double("Google::Auth::UserRefreshCredentials", fetch_access_token!: {access_token: 123})
    )
  end

  describe "#generate_image" do
    let(:prompt) { "A cartoon cat" }
    let(:model) { "imagen-3.0-generate-002" }
    let(:uri) { URI("#{subject.url}#{model}:predict") }
    let(:params) { {instances: [{prompt: prompt}], parameters: {sampleCount: 1}} }
    let(:api_response) { {"predictions" => [{"bytes" => "BASE64IMG"}]} }

    before do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(double(body: api_response.to_json))
    end

    it "returns wrapper with base64s" do
      resp = subject.generate_image(prompt: prompt)
      expect(resp).to be_a(Langchain::LLM::Response::GoogleVertexAIResponse)
      expect(resp.image_base64s).to eq(["BASE64IMG"])
    end
  end
end 
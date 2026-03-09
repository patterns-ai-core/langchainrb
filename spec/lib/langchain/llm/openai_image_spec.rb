# frozen_string_literal: true

require "openai"

RSpec.describe Langchain::LLM::OpenAI do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#generate_image" do
    let(:prompt) { "A cute baby sea otter" }
    let(:parameters) { {parameters: {prompt: prompt, n: 1, size: "1024x1024", model: "dall-e-3"}} }
    let(:openai_response) { {"created" => 1_721_918_400, "data" => [{"url" => "https://example.com/otter.png"}]} }

    before do
      images_stub = double("images")
      allow(subject.client).to receive(:images).and_return(images_stub)
      allow(images_stub).to receive(:generate).with(parameters).and_return(openai_response)
    end

    it "returns an OpenAIResponse with image URLs" do
      response = subject.generate_image(prompt: prompt)

      expect(response).to be_a(Langchain::LLM::Response::OpenAIResponse)
      expect(response.image_urls).to eq(["https://example.com/otter.png"])
    end
  end
end 
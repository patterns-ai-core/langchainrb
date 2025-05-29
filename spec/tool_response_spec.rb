# frozen_string_literal: true

require "spec_helper"

RSpec.describe Langchain::ToolResponse do
  describe "#initialize" do
    context "with content" do
      subject(:response) { described_class.new(content: "test content") }

      it "creates a valid instance" do
        expect(response).to be_a(described_class)
        expect(response.content).to eq("test content")
        expect(response.image_url).to be_nil
      end
    end

    context "with image_url" do
      subject(:response) { described_class.new(image_url: "http://example.com/image.jpg") }

      it "creates a valid instance" do
        expect(response).to be_a(described_class)
        expect(response.image_url).to eq("http://example.com/image.jpg")
        expect(response.content).to be_nil
      end
    end

    context "with both content and image_url" do
      subject(:response) { described_class.new(content: "test content", image_url: "http://example.com/image.jpg") }

      it "creates a valid instance" do
        expect(response).to be_a(described_class)
        expect(response.content).to eq("test content")
        expect(response.image_url).to eq("http://example.com/image.jpg")
      end
    end

    context "with neither content nor image_url" do
      it "raises an ArgumentError" do
        expect { described_class.new }.to raise_error(ArgumentError, "Either content or image_url must be provided")
      end
    end
  end
end

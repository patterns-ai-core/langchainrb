# frozen_string_literal: true

RSpec.describe Langchain::Utils::ImageWrapper do
  let(:image_url) { "./spec/fixtures/loaders/sf-cable-car.jpeg" }

  subject { described_class.new(image_url) }

  describe "#base64" do
    it "returns the image as a base64 string" do
      expect(subject.base64).to eq(Base64.strict_encode64(File.read(image_url)))
    end
  end

  xdescribe "#mime_type" do
    it "returns the mime type of the image" do
      expect(subject.mime_type).to eq("image/jpeg")
    end
  end
end

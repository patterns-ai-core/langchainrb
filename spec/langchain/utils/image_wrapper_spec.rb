# frozen_string_literal: true

RSpec.describe Langchain::Utils::ImageWrapper do
  let(:image_url) { "https://example.com/sf-cable-car.jpeg" }

  before do
    allow(URI).to receive(:open).with(image_url).and_return(File.open("./spec/fixtures/loaders/sf-cable-car.jpeg"))
  end

  subject { described_class.new(image_url) }

  describe "#base64" do
    it "returns the image as a base64 string" do
      expect(subject.base64).to eq(Base64.strict_encode64(File.read("./spec/fixtures/loaders/sf-cable-car.jpeg")))
    end
  end

  xdescribe "#mime_type" do
    it "returns the mime type of the image" do
      expect(subject.mime_type).to eq("image/jpeg")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::Assistant::Messages::GoogleGeminiMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_hash" do
    it "returns function" do
      message = described_class.new(role: "function", content: "4.0", tool_call_id: "calculator__execute")
      expect(message.to_hash).to eq({parts: [{functionResponse: {name: "calculator__execute", response: {content: "4.0", name: "calculator__execute"}}}], role: "function"})
    end

    it "returns all function responses in one message" do
      message = described_class.new(
        role: "function",
        content: ["first", "second"],
        tool_call_id: ["search__execute", "lookup__execute"]
      )

      expect(message.to_hash[:parts]).to eq([
        {functionResponse: {name: "search__execute", response: {content: "first", name: "search__execute"}}},
        {functionResponse: {name: "lookup__execute", response: {content: "second", name: "lookup__execute"}}}
      ])
    end

    it "returns tool_calls" do
      message = described_class.new(role: "model", tool_calls: [])
      expect(message.to_hash).to eq({parts: [{text: ""}], role: "model"})
    end

    it "returns the text and the image inline for an http(s) image_url" do
      message = described_class.new(role: "user", content: "Describe this image.", image_url: "https://example.com/image.jpg")
      allow(message).to receive(:image).and_return(double(base64: "base64_data", mime_type: "image/jpeg"))

      expect(message.to_hash).to eq({
        role: "user",
        parts: [
          {text: "Describe this image."},
          {inlineData: {mimeType: "image/jpeg", data: "base64_data"}}
        ]
      })
    end

    it "leaves out the text part when there is only an image" do
      message = described_class.new(role: "user", image_url: "https://example.com/image.png")
      allow(message).to receive(:image).and_return(double(base64: "base64_data", mime_type: "image/png"))

      expect(message.to_hash).to eq({
        role: "user",
        parts: [{inlineData: {mimeType: "image/png", data: "base64_data"}}]
      })
    end

    it "references a gs:// image_url as fileData without downloading it" do
      message = described_class.new(role: "user", content: "Describe this image.", image_url: "gs://bucket/photos/cat.JPG")
      expect(message).not_to receive(:image)

      expect(message.to_hash).to eq({
        role: "user",
        parts: [
          {text: "Describe this image."},
          {fileData: {mimeType: "image/jpeg", fileUri: "gs://bucket/photos/cat.JPG"}}
        ]
      })
    end

    it "raises when the mime type of a gs:// image_url can't be inferred" do
      message = described_class.new(role: "user", content: "Describe this.", image_url: "gs://bucket/file.bin")

      expect { message.to_hash }.to raise_error(ArgumentError, /Cannot infer the mime type of gs:\/\/bucket\/file.bin/)
    end
  end
end

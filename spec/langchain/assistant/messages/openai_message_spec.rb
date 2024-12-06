# frozen_string_literal: true

RSpec.describe Langchain::Assistant::Messages::OpenAIMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_hash" do
    context "when role is user" do
      let(:role) { "user" }
      context "when image_url is present" do
        let(:message) { described_class.new(role: "user", content: "Please describe this image", image_url: "https://example.com/image.jpg") }
        it "returns a user_hash with the image_url key" do
          expect(message.to_hash).to eq({
            role: "user",
            content: [
              {type: "text", text: "Please describe this image"},
              {type: "image_url", image_url: {url: "https://example.com/image.jpg"}}
            ]
          })
        end
      end
      context "when image_url is absent" do
        let(:message) { described_class.new(role: role, content: "Hello, how can I help you?") }

        it "returns user_hash" do
          described_class.new(role: role, content: "Hello, World")
          expect(message).to receive(:to_hash).and_call_original
          expect(message.to_hash).to eq({
            role: "user",
            content: [
              {type: "text", text: "Hello, how can I help you?"}

            ]
          })
        end
      end
    end

    context "when role is tool" do
      let(:message) { described_class.new(role: "tool", content: "Hello, world!", tool_calls: [], tool_call_id: "123") }

      it "returns a tool_hash" do
        expect(message.to_hash).to eq({role: "tool", content: [{type: "text", text: "Hello, world!"}], tool_call_id: "123"})
      end

      context "when image_url is present" do
        let(:message) { described_class.new(role: "tool", content: "Hello, world!", image_url: "https://example.com/image.jpg", tool_calls: [], tool_call_id: "123") }

        it "returns a tool_hash with the image_url key" do
          expect(message.to_hash).to eq({
            role: "tool",
            content: [
              {type: "text", text: "Hello, world!"},
              {type: "image_url", image_url: {url: "https://example.com/image.jpg"}}
            ],
            tool_call_id: "123"
          })
        end
      end
    end

    context "when role is assistant" do
      let(:tool_call) {
        {"id" => "call_9TewGANaaIjzY31UCpAAGLeV",
         "type" => "function",
         "function" => {"name" => "weather__execute", "arguments" => "{\"input\":\"Saint Petersburg\"}"}}
      }

      let(:message) { described_class.new(role: "assistant", tool_calls: [tool_call], tool_call_id: nil) }

      it "returns an assistant_hash" do
        expect(message.to_hash).to eq({role: "assistant", tool_calls: [tool_call]})
      end
    end
  end
end

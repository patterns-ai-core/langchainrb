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

      context "when input_audio is present with a .mp3" do
        let(:content) { "data:audio/mpeg;base64,abcdef"}
        let(:message) { described_class.new(role: "user", content: "Please describe this sound", input_audio: { data: content, format: "mp3" })}

        it "returns a user_hash with the input_audio key" do
          expect(message.to_hash).to eq({
            role: "user",
            content: [
              {type: "text", text: "Please describe this sound"},
              {type: "input_audio", input_audio: { data: content, format: "mp3" } }
            ]
          })
        end
      end

      context "when input_audio is present with a .wav" do
        let(:content) { "data:audio/wav;base64,abcdef"}
        let(:message) { described_class.new(role: "user", content: "Please describe this sound", input_audio: { data: content, format: "wav" })}

        it "returns a user_hash with the input_audio key" do
          expect(message.to_hash).to eq({
            role: "user",
            content: [
              {type: "text", text: "Please describe this sound"},
              {type: "input_audio", input_audio: { data: content, format: "wav" } }
            ]
          })
        end
      end

      context "when file is present with a pdf" do
        let(:content) { "data:application/pdf;base64,abcdef" }
        let(:message) { described_class.new(role: "user", content: "Please describe this document", file: { file_data: content, filename: "document.pdf" }) }

        it "returns a user_hash with the file key" do
          expect(message.to_hash).to eq({
            role: "user",
            content: [
              {type: "text", text: "Please describe this document"},
              {type: "file", file: { file_data: content, filename: "document.pdf"}}
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

# spec/langchain/messages/ollama_message_spec.rb

require "spec_helper"

RSpec.describe Langchain::Assistant::Messages::OllamaMessage do
  let(:valid_roles) { ["system", "assistant", "user", "tool"] }
  let(:role) { "assistant" }
  let(:content) { "This is a message" }
  let(:image_url) { "https://example.com/image.jpg" }
  let(:raw_response) { JSON.parse(File.read("spec/fixtures/llm/ollama/chat_with_tool_calls.json")) }
  let(:response) { Langchain::LLM::Response::OllamaResponse.new(raw_response) }
  let(:tool_calls) { response.tool_calls }
  let(:tool_call_id) { "12345" }

  describe "#initialize" do
    context "with valid arguments" do
      it "creates an instance of OllamaMessage" do
        message = described_class.new(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)
        expect(message).to be_an_instance_of(described_class)
      end
    end

    context "with an invalid role" do
      let(:role) { "invalid_role" }

      it "raises an ArgumentError" do
        expect { described_class.new(role: role) }.to raise_error(ArgumentError, "Role must be one of #{valid_roles.join(", ")}")
      end
    end

    context "with invalid tool_calls" do
      let(:tool_calls) { "invalid_tool_calls" }

      it "raises an ArgumentError" do
        expect { described_class.new(role: role, tool_calls: tool_calls) }.to raise_error(ArgumentError, "Tool calls must be an array of hashes")
      end
    end

    context "with invalid image_url" do
      let(:image_url) { "invalid_image_url" }

      it "raises an ArgumentError" do
        expect { described_class.new(role: role, image_url: image_url) }.to raise_error(ArgumentError, "image_url must be a valid url")
      end
    end
  end

  describe "#to_hash" do
    context "when role and content are not nil" do
      let(:message) { described_class.new(role: "user", content: "Hello, world!", tool_calls: [], tool_call_id: nil) }

      it "returns a hash with the role and content key" do
        expect(message.to_hash).to eq({role: "user", content: "Hello, world!"})
      end
    end

    context "when tool_call_id is not nil" do
      let(:message) { described_class.new(role: "tool", content: "Hello, world!", tool_calls: [], tool_call_id: "123") }

      it "returns a hash with the tool_call_id key" do
        expect(message.to_hash).to eq({role: "tool", content: "Hello, world!", tool_call_id: "123"})
      end
    end

    context "when tool_calls is not empty" do
      let(:tool_call) {
        {
          function: {
            name: "get_current_weather",
            arguments: {
              format: "celsius",
              location: "Paris"
            }
          }
        }
      }

      let(:message) { described_class.new(role: "assistant", content: "", tool_calls: [tool_call], tool_call_id: nil) }

      it "returns a hash with the tool_calls key" do
        expect(message.to_hash).to eq({role: "assistant", content: "", tool_calls: [tool_call]})
      end
    end

    context "with an image" do
      let(:message) { described_class.new(role: "user", content: "Describe this image", image_url: "https://example.com/image.jpg") }

      it "returns a hash with the images key" do
        allow(message).to receive(:image).and_return(double(base64: "base64_data", mime_type: "image/jpeg"))

        expect(message.to_hash).to eq({role: "user", content: "Describe this image", images: ["base64_data"]})
      end
    end
  end

  describe "#llm?" do
    context "when role is assistant" do
      it "returns true" do
        message = described_class.new(role: "assistant")
        expect(message.llm?).to be true
      end
    end

    context "when role is not assistant" do
      it "returns false" do
        message = described_class.new(role: "user")
        expect(message.llm?).to be false
      end
    end
  end

  describe "#assistant?" do
    context "when role is assistant" do
      it "returns true" do
        message = described_class.new(role: "assistant")
        expect(message.assistant?).to be true
      end
    end

    context "when role is not assistant" do
      it "returns false" do
        message = described_class.new(role: "user")
        expect(message.assistant?).to be false
      end
    end
  end

  describe "#system?" do
    context "when role is system" do
      it "returns true" do
        message = described_class.new(role: "system")
        expect(message.system?).to be true
      end
    end

    context "when role is not system" do
      it "returns false" do
        message = described_class.new(role: "user")
        expect(message.system?).to be false
      end
    end
  end

  describe "#tool?" do
    context "when role is tool" do
      it "returns true" do
        message = described_class.new(role: "tool")
        expect(message.tool?).to be true
      end
    end

    context "when role is not tool" do
      it "returns false" do
        message = described_class.new(role: "user")
        expect(message.tool?).to be false
      end
    end
  end
end

# spec/langchain/messages/ollama_message_spec.rb

require "spec_helper"

RSpec.describe Langchain::Messages::OllamaMessage do
  let(:valid_roles) { ["system", "assistant", "user", "tool"] }
  let(:role) { "assistant" }
  let(:content) { "This is a message" }
  let(:raw_response) { JSON.parse(File.read("spec/fixtures/llm/ollama/complete_mistral_tool_calls.json")) }
  let(:response) { Langchain::LLM::OllamaResponse.new(raw_response) }
  let(:tool_calls) { response.tool_calls }
  let(:tool_call_id) { "12345" }

  describe "#initialize" do
    context "with valid arguments" do
      it "creates an instance of OllamaMessage" do
        message = described_class.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
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
  end

  describe "#to_s" do
    context "when role is system" do
      it "returns the content as is" do
        message = described_class.new(role: "system", content: content)
        expect(message.to_s).to eq(content)
      end
    end

    context "when role is user" do
      it "returns the content wrapped with [INST] tags" do
        message = described_class.new(role: "user", content: content)
        expect(message.to_s).to eq("[INST] #{content}[/INST]")
      end
    end

    context "when role is tool" do
      it "returns the content wrapped with [TOOL_RESULTS] tags" do
        message = described_class.new(role: "tool", content: content)
        expect(message.to_s).to eq("[TOOL_RESULTS] #{content}[/TOOL_RESULTS]")
      end
    end

    context "when role is assistant and tool_calls are present" do
      it "returns the tool_calls formatted as a string" do
        message = described_class.new(role: "assistant", content: content, tool_calls: tool_calls)
        expect(message.to_s).to eq(%("[TOOL_CALLS] #{tool_calls}"))
      end
    end

    context "when role is assistant and tool_calls are absent" do
      it "returns the content as is" do
        message = described_class.new(role: "assistant", content: content, tool_calls: [])
        expect(message.to_s).to eq(content)
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

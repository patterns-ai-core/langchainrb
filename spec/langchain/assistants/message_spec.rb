# frozen_string_literal: true

RSpec.describe Langchain::Message do
  subject { described_class.new }

  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_openai_format" do
    context "when role and content are not nil" do
      let(:message) { described_class.new(role: "user", content: "Hello, world!", tool_calls: [], tool_call_id: nil) }

      it "returns a hash with the role and content key" do
        expect(message.to_openai_format).to eq({role: "user", content: "Hello, world!"})
      end
    end

    context "when tool_call_id is not nil" do
      let(:message) { described_class.new(role: "tool", content: "Hello, world!", tool_calls: [], tool_call_id: "123") }

      it "returns a hash with the tool_call_id key" do
        expect(message.to_openai_format).to eq({role: "tool", content: "Hello, world!", tool_call_id: "123"})
      end
    end

    context "when tool_calls is not empty" do
      let(:tool_call) {
        {"id" => "call_9TewGANaaIjzY31UCpAAGLeV",
         "type" => "function",
         "function" => {"name" => "weather-execute", "arguments" => "{\"input\":\"Saint Petersburg\"}"}}
      }

      let(:message) { described_class.new(role: "assistant", content: "", tool_calls: [tool_call], tool_call_id: nil) }

      it "returns a hash with the tool_calls key" do
        expect(message.to_openai_format).to eq({role: "assistant", content: "", tool_calls: [tool_call]})
      end
    end
  end
end

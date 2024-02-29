# frozen_string_literal: true

RSpec.describe Langchain::Thread do
  it "raises an error if messages array contains non-Langchain::Message instance(s)" do
    expect { described_class.new(messages: [Langchain::Message.new, "foo"]) }.to raise_error(ArgumentError)
  end

  describe "#openai_messages" do
    it "returns an array of messages in OpenAI format" do
      messages = [Langchain::Message.new(role: "user", content: "hello"),
        Langchain::Message.new(role: "assistant", content: "hi")]
      thread = described_class.new(messages: messages)

      openai_messages = thread.openai_messages

      expect(openai_messages).to be_an(Array)
      expect(openai_messages.length).to eq(messages.length)
      openai_messages.each do |message|
        expect(message).to be_a(Hash)
        expect(message).to have_key(:role)
        expect(message).to have_key(:content)
      end
    end
  end

  describe "#add_message" do
    let(:message) { Langchain::Message.new(role: "user", content: "hello") }

    it "adds a Langchain::Message instance to the messages array" do
      thread = described_class.new(messages: [])

      thread.add_message(message)

      expect(thread.messages).to include(message)
    end

    it "raises an error if the message is not a Langchain::Message instance" do
      thread = described_class.new(messages: [])

      expect { thread.add_message("foo") }.to raise_error(ArgumentError)
    end
  end
end

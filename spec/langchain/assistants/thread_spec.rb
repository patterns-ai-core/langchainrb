# frozen_string_literal: true

RSpec.describe Langchain::Thread do
  it "raises an error if messages array contains non-Langchain::Message instance(s)" do
    expect { described_class.new(messages: [Langchain::Messages::OpenAIMessage.new, "foo"]) }.to raise_error(ArgumentError)
  end

  describe "#openai_messages" do
    it "returns an array of messages in OpenAI format" do
      messages = [Langchain::Messages::OpenAIMessage.new(role: "user", content: "hello"),
        Langchain::Messages::OpenAIMessage.new(role: "assistant", content: "hi")]
      thread = described_class.new(messages: messages)

      openai_messages = thread.array_of_message_hashes

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
    let(:message) { Langchain::Messages::OpenAIMessage.new(role: "user", content: "hello") }

    it "adds a Langchain::Message instance to the messages array" do
      thread = described_class.new(messages: [])

      expect {
        thread.add_message(message)
      }.to change { thread.messages.count }.from(0).to(1)
      expect(thread.messages).to include(message)
    end

    it "raises an error if the message is not a Langchain::Message instance" do
      thread = described_class.new(messages: [])

      expect { thread.add_message("foo") }.to raise_error(ArgumentError)
    end
  end
end

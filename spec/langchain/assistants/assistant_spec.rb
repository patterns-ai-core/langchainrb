# frozen_string_literal: true

RSpec.describe Langchain::Assistant do
  let(:thread) { Langchain::Thread.new }
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  subject {
    described_class.new(
      llm: llm,
      thread: thread
    )
  }

  it "raises an error if tools array contains non-Langchain::Tool instance(s)" do
    expect { described_class.new(tools: [Langchain::Tool::Calculator.new, "foo"]) }.to raise_error(ArgumentError)
  end

  it "raises an error if LLM class does not implement `chat()` method" do
    expect { described_class.new(llm: llm) }.to raise_error(ArgumentError)
  end

  it "raises an error if thread is not an instance of Langchain::Thread" do
    expect { described_class.new(thread: "foo") }.to raise_error(ArgumentError)
  end

  describe "#add_message" do
    it "adds a message to the thread" do
      subject.add_message(content: "foo")
      expect(thread.messages.first.content).to eq("foo")
    end
  end
end

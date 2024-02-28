# frozen_string_literal: true

RSpec.describe Langchain::Assistant do
  let(:thread) { Langchain::Thread.new }
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  let(:calculator) { Langchain::Tool::Calculator.new }
  let(:instructions) { "You are an expert assistant" }

  subject {
    described_class.new(
      llm: llm,
      thread: thread,
      tools: [calculator],
      instructions: instructions
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

  describe "#initialize" do
    it "adds a system message to the thread" do
      described_class.new(llm: llm, thread: thread, instructions: instructions)
      expect(thread.messages.first.role).to eq("system")
      expect(thread.messages.first.content).to eq("You are an expert assistant")
    end
  end

  describe "#add_message" do
    it "adds a message to the thread" do
      subject.add_message(content: "foo")
      expect(thread.messages.last.content).to eq("foo")
    end
  end

  describe "submit_tool_output" do
    it "adds a message to the thread" do
      subject.submit_tool_output(tool_call_id: "123", output: "bar")
      expect(thread.messages.last.content).to eq("bar")
    end
  end
end

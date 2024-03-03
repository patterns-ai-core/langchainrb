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
      expect(thread.messages.last.role).to eq("user")
      expect(thread.messages.last.content).to eq("foo")
    end
  end

  describe "submit_tool_output" do
    it "adds a message to the thread" do
      subject.submit_tool_output(tool_call_id: "123", output: "bar")
      expect(thread.messages.last.role).to eq("tool")
      expect(thread.messages.last.content).to eq("bar")
    end
  end

  describe "#run" do
    context "when auto_tool_execution is false" do
      it "runs the assistant until a system message is received" do
        subject.add_message(role: "user", content: "Hello")
        subject.add_message(role: "assistant", content: "How can I assist you?")
        subject.add_message(role: "user", content: "I need help with calculations")
        subject.add_message(role: "assistant", tool_calls: [{tool: "calculator", input: "2+2"}])
        subject.add_message(role: "tool", content: "4")
        subject.add_message(role: "assistant", content: "Here is the result: 4")
        subject.add_message(role: "system", content: "End of conversation")

        expect(subject.run(auto_tool_execution: false)).to eq(thread.messages)
      end
    end

    context "when auto_tool_execution is true" do
      let(:tool_call) {
        {"id" => "call_9TewGANaaIjzY31UCpAAGLeV",
         "type" => "function",
         "function" => {"name" => "calculator-execute", "arguments" => "{\"input\":\"2+2\"}"}}
      }

      it "runs the assistant and automatically executes tool calls" do
        allow(subject.tools[0]).to receive(:execute).with(
          input: "2+2"
        ).and_return("4")

        tool_result = Langchain::Message.new(role: "tool", content: "4", tool_call_id: "call_9TewGANaaIjzY31UCpAAGLeV")
        allow(subject).to receive(:chat_with_llm).with(tool_choice: "auto").and_return(tool_result)

        assistant_result = Langchain::Message.new(role: "assistant", content: "Here is the result: 4")
        allow(subject.llm).to receive(:chat).and_return(assistant_result)

        subject.add_message(role: "user", content: "Please calculate 2+2")
        subject.add_message(role: "assistant", tool_calls: [tool_call])

        subject.run(auto_tool_execution: true)

        expect(subject.thread.messages[-2].content).to eq("4")
      end
    end
  end
end

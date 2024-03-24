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
    let(:openai_response) do
      {
        raw_response: {
          "id" => "chatcmpl-96QTYLFcp0haHHRhnqvTYL288357W",
          "object" => "chat.completion",
          "created" => 1711318768,
          "model" => "gpt-3.5-turbo-0125",
          "choices" =>
       [{"index" => 0,
         "message" =>
              {"role" => "assistant",
               "content" => nil,
               "tool_calls" =>
            [{"id" => "call_9TewGANaaIjzY31UCpAAGLeV",
              "type" => "function",
              "function" => {"name" => "calculator-execute", "arguments" => "{\"input\":\"2+2\"}"}}]},
         "logprobs" => nil,
         "finish_reason" => "tool_calls"}],
          "usage" => {"prompt_tokens" => 91, "completion_tokens" => 18, "total_tokens" => 109},
          "system_fingerprint" => "fp_3bc1b5746b"
        },
        model: "gpt-3.5-turbo-0125"
      }
    end

    context "when auto_tool_execution is false" do
      it "runs the assistant" do
        allow(subject.llm).to receive(:chat).and_return(openai_response)
        allow(openai_response).to receive(:tool_calls).and_return(openai_response[:raw_response]["choices"][0]["message"]["tool_calls"])
        allow(openai_response).to receive(:chat_completion).and_return(openai_response[:raw_response]["choices"][0]["message"]["content"])
        allow(openai_response).to receive(:role).and_return(openai_response[:raw_response]["choices"][0]["message"]["role"])

        subject.add_message(role: "user", content: "Please calculate 2+2")

        subject.run(auto_tool_execution: false)

        expect(subject.thread.messages[-1].role).to eq("assistant")
        expect(subject.thread.messages[-1].tool_calls).to eq([openai_response[:raw_response]["choices"][0]["message"]["tool_calls"]][0])
      end
    end

    context "when auto_tool_execution is true" do
      let(:openai_response2) do
        {
          raw_response: {
            "id" => "chatcmpl-96P6eEMDDaiwzRIHJZAliYHQ8ov3q",
            "object" => "chat.completion",
            "created" => 1711313504,
            "model" => "gpt-3.5-turbo-0125",
            "choices" => [{"index" => 0, "message" => {"role" => "assistant", "content" => "The result of 2 + 2 is 4."}, "logprobs" => nil, "finish_reason" => "stop"}],
            "usage" => {"prompt_tokens" => 121, "completion_tokens" => 13, "total_tokens" => 134},
            "system_fingerprint" => "fp_3bc1b5746c"
          },
          model: "gpt-3.5-turbo-0125"
        }
      end

      it "runs the assistant and automatically executes tool calls" do
        allow(subject.llm).to receive(:chat).and_return(openai_response2)
        allow(openai_response2).to receive(:tool_calls).and_return(nil)
        allow(openai_response2).to receive(:chat_completion).and_return(openai_response2[:raw_response]["choices"][0]["message"]["content"])
        allow(openai_response2).to receive(:role).and_return(openai_response2[:raw_response]["choices"][0]["message"]["role"])
        allow(subject.tools[0]).to receive(:execute).with(
          input: "2+2"
        ).and_return("4.0")

        subject.add_message(role: "user", content: "Please calculate 2+2")
        subject.add_message(role: "assistant", tool_calls: openai_response[:raw_response]["choices"][0]["message"]["tool_calls"])

        subject.run(auto_tool_execution: true)

        expect(subject.thread.messages[-2].role).to eq("tool")
        expect(subject.thread.messages[-2].content).to eq("4.0")

        expect(subject.thread.messages[-1].role).to eq("assistant")
        expect(subject.thread.messages[-1].content).to eq("The result of 2 + 2 is 4.")
      end
    end
  end
end

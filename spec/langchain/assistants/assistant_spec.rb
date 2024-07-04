# frozen_string_literal: true

RSpec.describe Langchain::Assistant do
  context "when llm is OpenAI" do
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
      llm = Langchain::LLM::Replicate.new(api_key: "123")
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

      it "sets new thread if thread is not provided" do
        subject = described_class.new(llm: llm, instructions: instructions)
        expect(subject.thread).to be_a(Langchain::Thread)
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
      let(:raw_openai_response) do
        {
          "id" => "chatcmpl-96QTYLFcp0haHHRhnqvTYL288357W",
          "object" => "chat.completion",
          "created" => 1711318768,
          "model" => "gpt-3.5-turbo-0125",
          "choices" => [
            {
              "index" => 0,
              "message" => {
                "role" => "assistant",
                "content" => nil,
                "tool_calls" => [
                  {
                    "id" => "call_9TewGANaaIjzY31UCpAAGLeV",
                    "type" => "function",
                    "function" => {"name" => "calculator__execute", "arguments" => "{\"input\":\"2+2\"}"}
                  }
                ]
              },
              "logprobs" => nil,
              "finish_reason" => "tool_calls"
            }
          ],
          "usage" => {"prompt_tokens" => 91, "completion_tokens" => 18, "total_tokens" => 109},
          "system_fingerprint" => "fp_3bc1b5746b"
        }
      end

      context "when auto_tool_execution is false" do
        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [
                {role: "system", content: instructions},
                {role: "user", content: "Please calculate 2+2"}
              ],
              tools: calculator.to_openai_tools,
              tool_choice: "auto"
            )
            .and_return(Langchain::LLM::OpenAIResponse.new(raw_openai_response))
        end

        it "runs the assistant" do
          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.run(auto_tool_execution: false)

          expect(subject.thread.messages.last.role).to eq("assistant")
          expect(subject.thread.messages.last.tool_calls).to eq([raw_openai_response["choices"][0]["message"]["tool_calls"]][0])
        end
      end

      context "when auto_tool_execution is true" do
        let(:raw_openai_response2) do
          {
            "id" => "chatcmpl-96P6eEMDDaiwzRIHJZAliYHQ8ov3q",
            "object" => "chat.completion",
            "created" => 1711313504,
            "model" => "gpt-3.5-turbo-0125",
            "choices" => [{"index" => 0, "message" => {"role" => "assistant", "content" => "The result of 2 + 2 is 4."}, "logprobs" => nil, "finish_reason" => "stop"}],
            "usage" => {"prompt_tokens" => 121, "completion_tokens" => 13, "total_tokens" => 134},
            "system_fingerprint" => "fp_3bc1b5746c"
          }
        end

        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [
                {role: "system", content: instructions},
                {role: "user", content: "Please calculate 2+2"},
                {role: "assistant", content: "", tool_calls: [
                  {
                    "function" => {"arguments" => "{\"input\":\"2+2\"}", "name" => "calculator__execute"},
                    "id" => "call_9TewGANaaIjzY31UCpAAGLeV",
                    "type" => "function"
                  }
                ]},
                {content: "4.0", role: "tool", tool_call_id: "call_9TewGANaaIjzY31UCpAAGLeV"}
              ],
              tools: calculator.to_openai_tools,
              tool_choice: "auto"
            )
            .and_return(Langchain::LLM::OpenAIResponse.new(raw_openai_response2))
        end

        it "runs the assistant and automatically executes tool calls" do
          allow(subject.tools[0]).to receive(:execute).with(
            input: "2+2"
          ).and_return("4.0")

          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.add_message(role: "assistant", tool_calls: raw_openai_response["choices"][0]["message"]["tool_calls"])

          subject.run(auto_tool_execution: true)

          expect(subject.thread.messages[-2].role).to eq("tool")
          expect(subject.thread.messages[-2].content).to eq("4.0")

          expect(subject.thread.messages[-1].role).to eq("assistant")
          expect(subject.thread.messages[-1].content).to eq("The result of 2 + 2 is 4.")
        end
      end

      context "when messages are empty" do
        let(:instructions) { nil }

        before do
          allow_any_instance_of(Langchain::ContextualLogger).to receive(:warn).with("No messages in the thread")
        end

        it "logs a warning" do
          expect(subject.thread.messages).to be_empty
          subject.run
          expect(Langchain.logger).to have_received(:warn).with("No messages in the thread")
        end
      end
    end

    describe "#extract_openai_tool_call" do
      let(:tool_call) { {"id" => "call_9TewGANaaIjzY31UCpAAGLeV", "type" => "function", "function" => {"name" => "calculator__execute", "arguments" => "{\"input\":\"2+2\"}"}} }

      it "returns correct data" do
        expect(subject.send(:extract_openai_tool_call, tool_call: tool_call)).to eq(["call_9TewGANaaIjzY31UCpAAGLeV", "calculator", "execute", {input: "2+2"}])
      end
    end
  end

  context "when llm is GoogleGemini" do
    let(:thread) { Langchain::Thread.new }
    let(:llm) { Langchain::LLM::GoogleGemini.new(api_key: "123") }
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
      llm = Langchain::LLM::Replicate.new(api_key: "123")
      expect { described_class.new(llm: llm) }.to raise_error(ArgumentError)
    end

    it "raises an error if thread is not an instance of Langchain::Thread" do
      expect { described_class.new(thread: "foo") }.to raise_error(ArgumentError)
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
        expect(thread.messages.last.role).to eq("function")
        expect(thread.messages.last.content).to eq("bar")
      end
    end

    describe "#run" do
      let(:raw_google_gemini_response) do
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  {
                    "functionCall" => {
                      "name" => "calculator__execute",
                      "args" => {"input" => "2+2"}
                    }
                  }
                ],
                "role" => "model"
              },
              "finishReason" => "STOP",
              "index" => 0,
              "safetyRatings" => []
            }
          ]
        }
      end

      context "when auto_tool_execution is false" do
        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [{role: "user", parts: [{text: "Please calculate 2+2"}]}],
              tools: calculator.to_google_gemini_tools,
              tool_choice: "auto",
              system: instructions
            )
            .and_return(Langchain::LLM::GoogleGeminiResponse.new(raw_google_gemini_response))
        end

        it "runs the assistant" do
          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.run(auto_tool_execution: false)

          expect(subject.thread.messages.last.role).to eq("model")
          expect(subject.thread.messages.last.tool_calls).to eq([raw_google_gemini_response["candidates"][0]["content"]["parts"]][0])
        end
      end

      context "when auto_tool_execution is true" do
        let(:raw_google_gemini_response2) do
          {
            "candidates" => [
              {
                "content" => {
                  "parts" => [{"text" => "The answer is 4.0"}],
                  "role" => "model"
                },
                "finishReason" => "STOP",
                "index" => 0,
                "safetyRatings" => []
              }
            ]
          }
        end

        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [
                {role: "user", parts: [{text: "Please calculate 2+2"}]},
                {role: "model", parts: [{"functionCall" => {"name" => "calculator__execute", "args" => {"input" => "2+2"}}}]},
                {role: "function", parts: [{functionResponse: {name: "calculator__execute", response: {name: "calculator__execute", content: "4.0"}}}]}
              ],
              tools: calculator.to_google_gemini_tools,
              tool_choice: "auto",
              system: instructions
            )
            .and_return(Langchain::LLM::GoogleGeminiResponse.new(raw_google_gemini_response2))
        end

        it "runs the assistant and automatically executes tool calls" do
          allow(subject.tools[0]).to receive(:execute).with(
            input: "2+2"
          ).and_return("4.0")

          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.add_message(role: "model", tool_calls: raw_google_gemini_response["candidates"][0]["content"]["parts"])

          subject.run(auto_tool_execution: true)

          expect(subject.thread.messages[-2].role).to eq("function")
          expect(subject.thread.messages[-2].content).to eq("4.0")

          expect(subject.thread.messages[-1].role).to eq("model")
          expect(subject.thread.messages[-1].content).to eq("The answer is 4.0")
        end
      end

      context "when messages are empty" do
        let(:instructions) { nil }

        before do
          allow_any_instance_of(Langchain::ContextualLogger).to receive(:warn).with("No messages in the thread")
        end

        it "logs a warning" do
          expect(subject.thread.messages).to be_empty
          subject.run
          expect(Langchain.logger).to have_received(:warn).with("No messages in the thread")
        end
      end
    end

    describe "#extract_google_gemini_tool_call" do
      let(:tool_call) { {"functionCall" => {"name" => "calculator__execute", "args" => {"input" => "2+2"}}} }

      it "returns correct data" do
        expect(subject.send(:extract_google_gemini_tool_call, tool_call: tool_call)).to eq(["calculator__execute", "calculator", "execute", {input: "2+2"}])
      end
    end
  end

  context "when llm is Anthropic" do
    let(:thread) { Langchain::Thread.new }
    let(:llm) { Langchain::LLM::Anthropic.new(api_key: "123") }
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
      llm = Langchain::LLM::Replicate.new(api_key: "123")
      expect { described_class.new(llm: llm) }.to raise_error(ArgumentError)
    end

    it "raises an error if thread is not an instance of Langchain::Thread" do
      expect { described_class.new(thread: "foo") }.to raise_error(ArgumentError)
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
        expect(thread.messages.last.role).to eq("tool_result")
        expect(thread.messages.last.content).to eq("bar")
      end
    end

    describe "#run" do
      let(:raw_anthropic_response) do
        {
          "id" => "msg_01FqxtJoQCu8ixTCmrtCq6L5",
          "type" => "message",
          "role" => "assistant",
          "model" => "claude-3-sonnet-20240229",
          "stop_sequence" => nil,
          "usage" => {
            "input_tokens" => 272,
            "output_tokens" => 55
          },
          "content" => [
            {
              "type" => "tool_use",
              "id" => "toolu_014eSx9oBA5DMe8gZqaqcJ3H",
              "name" => "calculator__execute",
              "input" => {
                "input" => "2+2"
              }
            }
          ],
          "stop_reason" => "tool_use"
        }
      end

      context "when not using tools" do
        subject {
          described_class.new(
            llm: llm,
            thread: thread,
            instructions: instructions
          )
        }

        it "adds a system param to chat when instructions are given" do
          expect(subject.llm).to receive(:chat)
            .with(
              hash_including(
                system: instructions
              )
            ).and_return(Langchain::LLM::AnthropicResponse.new(raw_anthropic_response))
          subject.add_message content: "Please calculate 2+2"
          subject.run
        end
      end

      context "when auto_tool_execution is false" do
        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [{role: "user", content: "Please calculate 2+2"}],
              tools: calculator.to_anthropic_tools,
              tool_choice: {type: "auto"},
              system: instructions
            )
            .and_return(Langchain::LLM::AnthropicResponse.new(raw_anthropic_response))
        end

        it "runs the assistant" do
          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.run(auto_tool_execution: false)

          expect(subject.thread.messages.last.role).to eq("assistant")
          expect(subject.thread.messages.last.tool_calls).to eq([raw_anthropic_response["content"].first])
        end

        it "adds a system param to chat when instructions are given" do
          expect(subject.llm).to receive(:chat)
            .with(
              hash_including(
                system: instructions
              )
            ).and_return(Langchain::LLM::AnthropicResponse.new(raw_anthropic_response))
          subject.add_message content: "Please calculate 2+2"
          subject.run
        end
      end

      context "when auto_tool_execution is true" do
        let(:raw_anthropic_response2) do
          {
            "role" => "assistant",
            "content" => [
              {
                "type" => "text",
                "text" => "So 2 + 2 = 4."
              }
            ]
          }
        end

        before do
          allow(subject.llm).to receive(:chat)
            .with(
              messages: [
                {role: "user", content: "Please calculate 2+2"},
                {role: "assistant", content: [
                  {
                    "type" => "tool_use",
                    "id" => "toolu_014eSx9oBA5DMe8gZqaqcJ3H",
                    "name" => "calculator__execute",
                    "input" => {"input" => "2+2"}
                  }
                ]},
                {role: "user", content: [{type: "tool_result", tool_use_id: "toolu_014eSx9oBA5DMe8gZqaqcJ3H", content: "4.0"}]}
              ],
              tools: calculator.to_anthropic_tools,
              tool_choice: {type: "auto"},
              system: instructions
            )
            .and_return(Langchain::LLM::AnthropicResponse.new(raw_anthropic_response2))
        end

        it "runs the assistant and automatically executes tool calls" do
          allow(subject.tools[0]).to receive(:execute).with(
            input: "2+2"
          ).and_return("4.0")

          subject.add_message(role: "user", content: "Please calculate 2+2")
          subject.add_message(role: "assistant", tool_calls: raw_anthropic_response["content"])

          subject.run(auto_tool_execution: true)

          expect(subject.thread.messages[-2].role).to eq("tool_result")
          expect(subject.thread.messages[-2].content).to eq("4.0")

          expect(subject.thread.messages[-1].role).to eq("assistant")
          expect(subject.thread.messages[-1].content).to eq("So 2 + 2 = 4.")
        end
      end

      context "when messages are empty" do
        let(:instructions) { nil }

        before do
          allow_any_instance_of(Langchain::ContextualLogger).to receive(:warn).with("No messages in the thread")
        end

        it "logs a warning" do
          expect(subject.thread.messages).to be_empty
          subject.run
          expect(Langchain.logger).to have_received(:warn).with("No messages in the thread")
        end
      end
    end

    describe "#extract_anthropic_tool_call" do
      let(:tool_call) {
        {
          "type" => "tool_use",
          "id" => "toolu_01TjusbFApEbwKPRWTRwzadR",
          "name" => "news_retriever__get_top_headlines",
          "input" => {
            "country" => "us",
            "page_size" => 10
          }
        }
      }

      it "returns correct data" do
        expect(subject.send(:extract_anthropic_tool_call, tool_call: tool_call)).to eq(["toolu_01TjusbFApEbwKPRWTRwzadR", "news_retriever", "get_top_headlines", {country: "us", page_size: 10}])
      end
    end
  end

  xdescribe "#clear_thread!"

  xdescribe "#instructions="
end

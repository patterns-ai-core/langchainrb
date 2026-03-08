# frozen_string_literal: true

require "anthropic"

RSpec.describe Langchain::LLM::Anthropic do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#supports?" do
    it "supports chat" do
      expect(subject.supports?(:chat)).to be true
    end

    it "supports streaming" do
      expect(subject.supports?(:streaming)).to be true
    end

    it "supports tools" do
      expect(subject.supports?(:tools)).to be true
    end

    it "does not support embedding" do
      expect(subject.supports?(:embedding)).to be false
    end
  end

  describe "#initialize" do
    context "when default_options are passed" do
      let(:default_options) { {max_tokens: 512} }

      subject { described_class.new(api_key: "123", default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:max_tokens]).to eq(512)
      end

      it "get passed to consecutive chat() call" do
        subject
        expect(subject.client.messages).to receive(:create).with(hash_including(default_options)).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
      end

      it "can be overridden" do
        subject
        expect(subject.client.messages).to receive(:create).with(hash_including({max_tokens: 1024})).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}], max_tokens: 1024)
      end
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", content: "How high is the sky?"}] }
    let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat.json") }
    let(:response) { JSON.parse(fixture, symbolize_names: true) }

    context "with no additional parameters" do
      before do
        allow(subject.client.messages).to receive(:create)
          .with({
            model: described_class::DEFAULTS[:chat_model],
            messages: messages,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens: described_class::DEFAULTS[:max_tokens],
            stop_sequences: ["beep"]
          })
          .and_return(response)
      end

      it "returns a completion" do
        expect(
          subject.chat(messages: messages, stop_sequences: ["beep"]).chat_completion
        ).to eq("The sky doesn't have a defined height or upper limit.")
      end

      it "returns model attribute" do
        expect(
          subject.chat(messages: messages, stop_sequences: ["beep"]).model
        ).to eq("claude-3-sonnet-20240229")
      end
    end

    context "with thinking parameter" do
      let(:thinking_params) { {type: "enabled", budget_tokens: 4000} }

      context "passed in default_options" do
        subject { described_class.new(api_key: "123", default_options: {thinking: thinking_params}) }

        it "includes thinking parameter in the request" do
          expect(subject.client.messages).to receive(:create)
            .with(hash_including(thinking: thinking_params))
            .and_return(response)
          subject.chat(messages: messages)
        end
      end

      context "passed directly to chat method" do
        it "includes thinking parameter in the request" do
          expect(subject.client.messages).to receive(:create)
            .with(hash_including(thinking: thinking_params))
            .and_return(response)
          subject.chat(messages: messages, thinking: thinking_params)
        end
      end
    end

    context "with streaming" do
      let(:stream_handler) { proc { _1 } }

      let(:mock_stream) do
        instance_double("Anthropic::Streaming::MessageStream").tap do |stream|
          allow(stream).to receive(:each).and_yield("event1").and_yield("event2")
          allow(stream).to receive(:accumulated_message).and_return(accumulated_message)
        end
      end

      let(:accumulated_message) do
        Anthropic::Models::Message.new(
          id: "msg_019s6T825xb66ZLwPWmvH875",
          type: :message,
          model: "claude-3-sonnet-20240229",
          role: :assistant,
          content: [Anthropic::Models::TextBlock.new(type: :text, text: "Life is pretty good")],
          stop_reason: :max_tokens,
          usage: Anthropic::Models::Usage.new(input_tokens: 5, output_tokens: 10)
        )
      end

      before do
        allow(subject.client.messages).to receive(:stream).and_return(mock_stream)
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(10)
        expect(rsp.total_tokens).to eq(15)
        expect(rsp.chat_completion).to eq("Life is pretty good")
      end

      it "yields events to the block" do
        events = []
        subject.chat(messages: messages) { |event| events << event }
        expect(events).to eq(["event1", "event2"])
      end
    end

    context "with streaming tools" do
      let(:stream_handler) { proc { _1 } }

      let(:mock_stream) do
        instance_double("Anthropic::Streaming::MessageStream").tap do |stream|
          allow(stream).to receive(:each)
          allow(stream).to receive(:accumulated_message).and_return(accumulated_message)
        end
      end

      let(:accumulated_message) do
        Anthropic::Models::Message.new(
          id: "msg_014p7gG3wDgGV9EUtLvnow3U",
          type: :message,
          model: "claude-3-haiku-20240307",
          role: :assistant,
          content: [
            Anthropic::Models::TextBlock.new(type: :text, text: "Okay, let's check the weather for San Francisco, CA:"),
            Anthropic::Models::ToolUseBlock.new(
              type: :tool_use,
              id: "toolu_01T1x1fJ34qAmk2tNTrN7Up6",
              name: "get_weather",
              input: {location: "San Francisco, CA", unit: "fahrenheit"}
            )
          ],
          stop_reason: :tool_use,
          usage: Anthropic::Models::Usage.new(input_tokens: 472, output_tokens: 89)
        )
      end

      before do
        allow(subject.client.messages).to receive(:stream).and_return(mock_stream)
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(89)
        expect(rsp.total_tokens).to eq(561)
        expect(rsp.chat_completion).to eq("Okay, let's check the weather for San Francisco, CA:")

        expect(rsp.tool_calls.first[:name]).to eq("get_weather")
        expect(rsp.tool_calls.first[:input]).to eq({location: "San Francisco, CA", unit: "fahrenheit"})
      end

      context "response has empty input" do
        let(:accumulated_message) do
          Anthropic::Models::Message.new(
            id: "msg_014p7gG3wDgGV9EUtLvnow3U",
            type: :message,
            model: "claude-3-haiku-20240307",
            role: :assistant,
            content: [
              Anthropic::Models::TextBlock.new(type: :text, text: "I'll check the weather for you:"),
              Anthropic::Models::ToolUseBlock.new(
                type: :tool_use,
                id: "toolu_01T1x1fJ34qAmk2tNTrN7Up6",
                name: "get_weather",
                input: nil
              )
            ],
            stop_reason: :tool_use,
            usage: Anthropic::Models::Usage.new(input_tokens: 0, output_tokens: 10)
          )
        end

        it "handles empty input in tool calls correctly" do
          rsp = subject.chat(messages: [{role: "user", content: "What's the weather?"}], &stream_handler)

          expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
          expect(rsp.chat_completion).to eq("I'll check the weather for you:")

          expect(rsp.tool_calls.first[:name]).to eq("get_weather")
          expect(rsp.tool_calls.first[:input]).to be_nil
        end
      end
    end
  end
end

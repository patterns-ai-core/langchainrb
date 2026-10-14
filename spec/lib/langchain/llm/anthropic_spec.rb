# frozen_string_literal: true

require "anthropic"

RSpec.describe Langchain::LLM::Anthropic do
  let(:subject) { described_class.new(api_key: "123") }

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

  describe "#complete" do
    it "is not supported, as Claude models are only served through the Messages API" do
      expect { subject.complete(prompt: "How high is the sky?") }
        .to raise_error(NotImplementedError, "Langchain::LLM::Anthropic does not support completion")
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", content: "How high is the sky?"}] }
    let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat.json") }
    let(:response) { JSON.parse(fixture, symbolize_names: true) }

    context "with temperature" do
      it "does not send the library's default temperature, which current Claude models reject" do
        expect(subject.client.messages).to receive(:create)
          .with(hash_excluding(:temperature))
          .and_return(response)

        subject.chat(messages: messages)
      end

      it "sends a temperature set in default_options" do
        llm = described_class.new(api_key: "123", default_options: {temperature: 0.2})
        expect(llm.client.messages).to receive(:create)
          .with(hash_including(temperature: 0.2))
          .and_return(response)

        llm.chat(messages: messages)
      end

      it "sends a temperature passed to #chat" do
        expect(subject.client.messages).to receive(:create)
          .with(hash_including(temperature: 0.7))
          .and_return(response)

        subject.chat(messages: messages, temperature: 0.7)
      end
    end

    context "with no additional parameters" do
      before do
        allow(subject.client.messages).to receive(:create)
          .with({
            model: described_class::DEFAULTS[:chat_model],
            messages: messages,
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
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream.json") }
      let(:response) { JSON.parse(fixture) }
      let(:stream_handler) { proc { _1 } }

      before do
        allow(subject.client.messages).to receive(:create) do |parameters|
          response.each do |chunk|
            parameters[:stream].call(chunk)
          end
        end
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(10)
        expect(rsp.total_tokens).to eq(10)
        expect(rsp.chat_completion).to eq("Life is pretty good")
      end
    end

    context "with streaming and a thinking block" do
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream_with_thinking.json") }
      let(:response) { JSON.parse(fixture) }
      let(:stream_handler) { proc { _1 } }

      before do
        allow(subject.client.messages).to receive(:create) do |parameters|
          response.each do |chunk|
            parameters[:stream].call(chunk)
          end
        end
      end

      it "returns the text after the thinking block" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp.chat_completion).to eq("Life is pretty good")
        expect(rsp.tool_calls).to eq([])
      end

      it "keeps the thinking block with its signature" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp.chat_completions.first).to eq(
          {type: "thinking", thinking: "The user is greeting me.", signature: "EqQBCgIYAhIM"}
        )
      end
    end

    context "with streaming tools" do
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream_with_tool_calls.json") }
      let(:response) { JSON.parse(fixture) }
      let(:stream_handler) { proc { _1 } }

      before do
        allow(subject.client.messages).to receive(:create) do |parameters|
          response.each do |chunk|
            parameters[:stream].call(chunk)
          end
        end
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(89)
        expect(rsp.total_tokens).to eq(89)
        expect(rsp.chat_completion).to eq("Okay, let's check the weather for San Francisco, CA:")

        expect(rsp.tool_calls.first[:name]).to eq("get_weather")
        expect(rsp.tool_calls.first[:input]).to eq({location: "San Francisco, CA", unit: "fahrenheit"})
      end

      context "response has empty input" do
        let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream_with_empty_tool_input.json") }

        it "handles empty input in tool calls correctly" do
          # The test will pass if no exception is raised during processing
          rsp = subject.chat(messages: [{role: "user", content: "What's the weather?"}], &stream_handler)

          # Verify the response
          expect(rsp).to be_a(Langchain::LLM::Response::AnthropicResponse)
          expect(rsp.chat_completion).to eq("I'll check the weather for you:")

          # Verify the tool call with empty input is handled correctly
          expect(rsp.tool_calls.first[:name]).to eq("get_weather")
          expect(rsp.tool_calls.first[:input]).to eq({})
        end
      end
    end
  end
end

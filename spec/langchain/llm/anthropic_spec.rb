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
        expect(subject.client).to receive(:messages).with(parameters: hash_including(default_options)).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
      end

      it "can be overridden" do
        subject
        expect(subject.client).to receive(:messages).with(parameters: hash_including({max_tokens: 1024})).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}], max_tokens: 1024)
      end
    end
  end

  describe "#complete" do
    let(:completion) { "How high is the sky?" }
    let(:fixture) { File.read("spec/fixtures/llm/anthropic/complete.json") }
    let(:response) { JSON.parse(fixture) }

    context "with no additional parameters" do
      before do
        allow(subject.client).to receive(:complete)
          .with(parameters: {
            model: described_class::DEFAULTS[:completion_model],
            prompt: completion,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens_to_sample: described_class::DEFAULTS[:max_tokens]
          })
          .and_return(response)
      end

      it "returns a completion" do
        expect(subject.complete(prompt: completion).completion).to eq(" The sky has no definitive")
      end

      it "returns model attribute" do
        expect(subject.complete(prompt: completion).model).to eq("claude-2.1")
      end
    end

    context "with failed API call" do
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/error.json") }

      before do
        allow(subject.client).to receive(:complete)
          .with(parameters: {
            model: described_class::DEFAULTS[:completion_model],
            prompt: completion,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens_to_sample: described_class::DEFAULTS[:max_tokens]
          })
          .and_return(JSON.parse(fixture))
      end

      it "raises an error" do
        expect { subject.complete(prompt: completion) }.to raise_error(Langchain::LLM::ApiError, "Anthropic API error: The request is invalid. Please check the request and try again.")
      end
    end
  end

  describe "#chat" do
    let(:messages) { [{role: "user", content: "How high is the sky?"}] }
    let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat.json") }
    let(:response) { JSON.parse(fixture) }

    context "with no additional parameters" do
      before do
        allow(subject.client).to receive(:messages)
          .with(parameters: {
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
          expect(subject.client).to receive(:messages)
            .with(parameters: hash_including(thinking: thinking_params))
            .and_return(response)
          subject.chat(messages: messages)
        end
      end

      context "passed directly to chat method" do
        it "includes thinking parameter in the request" do
          expect(subject.client).to receive(:messages)
            .with(parameters: hash_including(thinking: thinking_params))
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
        allow(subject.client).to receive(:messages) do |parameters|
          response.each do |chunk|
            parameters[:parameters][:stream].call(chunk)
          end
        end.and_return("This response will be overritten.")
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(10)
        expect(rsp.total_tokens).to eq(10)
        expect(rsp.chat_completion).to eq("Life is pretty good")
      end
    end

    context "with streaming tools" do
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream_with_tool_calls.json") }
      let(:response) { JSON.parse(fixture) }
      let(:stream_handler) { proc { _1 } }

      before do
        allow(subject.client).to receive(:messages) do |parameters|
          response.each do |chunk|
            parameters[:parameters][:stream].call(chunk)
          end
        end.and_return("This response will be overritten.")
      end

      it "handles streaming responses correctly" do
        rsp = subject.chat(messages: messages, &stream_handler)
        expect(rsp).to be_a(Langchain::LLM::AnthropicResponse)
        expect(rsp.completion_tokens).to eq(89)
        expect(rsp.total_tokens).to eq(89)
        expect(rsp.chat_completion).to eq("Okay, let's check the weather for San Francisco, CA:")

        expect(rsp.tool_calls.first["name"]).to eq("get_weather")
        expect(rsp.tool_calls.first["input"]).to eq({location: "San Francisco, CA", unit: "fahrenheit"})
      end

      context "response has empty input" do
        let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_stream_with_empty_tool_input.json") }

        it "handles empty input in tool calls correctly" do
          # The test will pass if no exception is raised during processing
          rsp = subject.chat(messages: [{role: "user", content: "What's the weather?"}], &stream_handler)

          # Verify the response
          expect(rsp).to be_a(Langchain::LLM::AnthropicResponse)
          expect(rsp.chat_completion).to eq("I'll check the weather for you:")

          # Verify the tool call with empty input is handled correctly
          expect(rsp.tool_calls.first["name"]).to eq("get_weather")
          expect(rsp.tool_calls.first["input"]).to be_nil  # Should be nil (null in Ruby) because input was empty
        end
      end
    end
  end
end

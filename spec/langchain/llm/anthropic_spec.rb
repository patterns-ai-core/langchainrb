# frozen_string_literal: true

require "anthropic"

RSpec.describe Langchain::LLM::Anthropic do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#complete" do
    let(:completion) { "How high is the sky?" }
    let(:fixture) { File.read("spec/fixtures/llm/anthropic/complete.json") }
    let(:response) { JSON.parse(fixture) }

    context "with no additional parameters" do
      before do
        allow(subject.client).to receive(:complete)
          .with(parameters: {
            model: described_class::DEFAULTS[:completion_model_name],
            prompt: completion,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens_to_sample: described_class::DEFAULTS[:max_tokens_to_sample]
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
            model: described_class::DEFAULTS[:completion_model_name],
            prompt: completion,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens_to_sample: described_class::DEFAULTS[:max_tokens_to_sample]
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
            model: described_class::DEFAULTS[:chat_completion_model_name],
            messages: messages,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens: described_class::DEFAULTS[:max_tokens_to_sample],
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
        expect(rsp.tool_calls.first["input"]).to eq('{"location": "San Francisco, CA", "unit": "fahrenheit"}')
      end
    end
  end
end

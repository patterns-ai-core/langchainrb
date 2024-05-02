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
    end
  end

  describe "#chat" do
    let(:response) { JSON.parse(fixture) }

    context "with no additional parameters" do
      let(:messages) { [{role: "user", content: "How high is the sky?"}] }
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat.json") }

      before do
        allow(subject.client).to receive(:messages)
          .with(parameters: {
            model: described_class::DEFAULTS[:chat_completion_model_name],
            messages: messages,
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens: described_class::DEFAULTS[:max_tokens_to_sample]
          })
          .and_return(response)
      end

      it "returns a completion" do
        expect(subject.chat(messages: messages).chat_completion).to eq("The sky doesn't have a defined height or upper limit.")
      end
    end

    context "with system parameter and system role messages" do
      let(:system) { "Answer in English." }
      let(:messages) do
        [{role: "system", content: "Answer in 1 words."},
          {role: "user", content: "How high is the sky?"},
          {role: "system", content: "Answer with a word starting with B."}]
      end
      let(:fixture) { File.read("spec/fixtures/llm/anthropic/chat_with_system.json") }

      before do
        allow(subject.client)
          .to receive(:messages)
          .with(parameters: {
            model: described_class::DEFAULTS[:chat_completion_model_name],
            system: <<~SYSTEM.strip,
              Answer in English.
              Answer in 1 words.
              Answer with a word starting with B.
            SYSTEM
            messages: [{role: "user", content: "How high is the sky?"}],
            temperature: described_class::DEFAULTS[:temperature],
            max_tokens: described_class::DEFAULTS[:max_tokens_to_sample]
          })
          .and_return(response)
      end

      it "returns a completion" do
        expect(subject.chat(system: system, messages: messages).chat_completion)
          .to eq("Boundless.")
      end
    end
  end
end

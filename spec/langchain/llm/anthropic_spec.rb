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
end

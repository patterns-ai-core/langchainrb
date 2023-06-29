# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLength::AI21Validator do
  describe "#validate_max_tokens!" do
    subject { described_class.validate_max_tokens!(content, model, client) }

    let(:client) { Langchain::LLM::AI21.new(api_key: "123") }
    let(:model) { "j2-light" }

    context "with text argument" do
      context "when the text is too long" do
        let(:content) { "lorem ipsum" * 9000 }

        before do
          allow(described_class).to receive(:token_length).and_return(10000)
        end

        it "raises an error" do
          expect {
            subject
          }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 8192 tokens, but the given text is 10000 tokens long.")
        end
      end

      context "when the text is not too long" do
        let(:content) { "lorem ipsum" * 10 }

        before do
          allow(described_class).to receive(:token_length).and_return(
            2000
          )
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "returns the correct max_tokens" do
          expect(subject).to eq(6192)
        end
      end
    end

    context "with array argument" do
      let(:content) { ["lorem ipsum" * 10, "lorem ipsum" * 10] }

      before do
        allow(described_class).to receive(:token_length).and_return(
          2000
        )
      end

      context "when the text is not too long" do
        it "returns the correct max_tokens" do
          expect(subject).to eq(4192)
        end
      end
    end
  end
end

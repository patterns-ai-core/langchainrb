# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLength::CohereValidator do
  describe "#validate_max_tokens!" do
    subject { described_class.validate_max_tokens!(content, model, client) }

    context "with text argument" do
      context "when the text is too long" do
        let(:content) { "lorem ipsum" * 9000 }
        let(:model) { "base" }
        let(:client) { Langchain::LLM::Cohere.new(api_key: "123") }

        before do
          allow(described_class).to receive(:token_length).and_return(
            4096
          )
        end

        it "raises an error" do
          expect {
            subject
          }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 2048 tokens, but the given text is 4096 tokens long.")
        end
      end

      context "when the text is not too long" do
        let(:content) { "lorem ipsum" * 10 }
        let(:model) { "base" }
        let(:client) { Langchain::LLM::Cohere.new(api_key: "123") }

        before do
          allow(described_class).to receive(:token_length).and_return(
            790
          )
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "returns the correct max_tokens" do
          expect(subject).to eq(1258)
        end
      end
    end

    context "with array argument" do
      let(:content) { ["lorem ipsum" * 10, "lorem ipsum" * 10] }
      let(:model) { "base" }
      let(:client) { Langchain::LLM::Cohere.new(api_key: "123") }

      before do
        allow(described_class).to receive(:token_length).and_return(
          790
        )
      end

      context "when the text is not too long" do
        it "returns the correct max_tokens" do
          expect(subject).to eq(468)
        end
      end
    end
  end
end

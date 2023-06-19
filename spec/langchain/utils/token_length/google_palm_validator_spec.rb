# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLength::GooglePalmValidator do
  let(:llm) { Langchain::LLM::GooglePalm.new(api_key: "123") }
  let(:model) { "chat-bison-001" }

  before do
    allow(llm.client).to receive(:count_message_tokens).and_return(
      {"tokenCount" => token_length}
    )
  end

  describe "#validate_max_tokens!" do
    subject { described_class.validate_max_tokens!(content, model, llm: llm) }

    context "with text argument" do
      context "when the text is too long" do
        let(:token_length) { 4000 }

        let(:content) { "lorem ipsum" * 9000 }

        it "raises an error" do
          expect {
            subject
          }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 4000 tokens, but the given text is 4000 tokens long.")
        end
      end

      context "when the text is not too long" do
        let(:token_length) { 200 }

        let(:content) { "lorem ipsum" * 100 }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "returns the correct max_tokens" do
          expect(subject).to eq(3800)
        end
      end
    end

    context "with array argument" do
      let(:token_length) { 500 }

      let(:content) { ["lorem ipsum" * 100, "lorem ipsum" * 100] }

      context "when the text is not too long" do
        it "returns the correct max_tokens" do
          expect(subject).to eq(3000)
        end
      end
    end
  end
end

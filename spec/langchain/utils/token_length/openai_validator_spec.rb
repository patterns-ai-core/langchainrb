# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLength::OpenAIValidator do
  describe "#validate_max_tokens!" do
    subject { described_class.validate_max_tokens!(content, model) }

    context "with text argument" do
      context "when the text is too long" do
        let(:content) { "lorem ipsum" * 9000 }
        let(:model) { "text-davinci-003" }

        it "raises an error" do
          expect {
            subject
          }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 4097 tokens, but the given text is 45000 tokens long.")
        end
      end

      context "when the text is not too long" do
        let(:content) { "lorem ipsum" * 100 }
        let(:model) { "gpt-4" }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "returns the correct max_tokens" do
          expect(subject).to eq(7892)
        end
      end

      context "when the model has a separate completion token limit" do
        let(:model) { "gpt-4-1106-preview" }

        context "where the leftover tokens are great than the completion token limit" do
          # 202 tokens
          let(:content) { "lorem ipsum " * 100 }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "returns the correct max_tokens" do
            expect(subject).to eq(4096)
          end
        end

        context "where the leftover tokens are below the completion token limit" do
          # 126002 tokens, just under the input token limit of gpt-4-1106-preview
          let(:content) { "lorem ipsum " * 63_000 }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "returns the correct max_tokens" do
            expect(subject).to eq(1998)
          end
        end
      end

      context "when the token is equal to the limit" do
        let(:content) { "lorem ipsum" * 9000 }
        let(:model) { "text-embedding-ada-002" }

        before do
          allow(described_class).to receive(:token_length).and_return(
            Langchain::Utils::TokenLength::OpenAIValidator::TOKEN_LIMITS[model]
          )
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "returns the correct max_tokens" do
          expect(subject).to eq(0)
        end
      end

      context "when :max_tokens is passed in" do
        context "when :max_tokens is lower than the leftover tokens" do
          subject { described_class.validate_max_tokens!(content, model, max_tokens: 10) }
          let(:content) { "lorem ipsum" * 100 }
          let(:model) { "gpt-4" }

          it "returns the correct max_tokens" do
            expect(subject).to eq(10)
          end
        end

        context "when :max_tokens is greater than the leftover tokens" do
          subject { described_class.validate_max_tokens!(content, model, max_tokens: 8000) }
          let(:content) { "lorem ipsum" * 100 }
          let(:model) { "gpt-4" }

          it "returns the correct max_tokens" do
            expect(subject).to eq(7892)
          end
        end
      end
    end

    context "with array argument" do
      let(:content) { ["lorem ipsum" * 100, "lorem ipsum" * 100] }
      let(:model) { "gpt-4" }

      context "when the text is not too long" do
        it "returns the correct max_tokens" do
          expect(subject).to eq(7588)
        end
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLengthValidator do
  describe "#validate!" do
    context "when the text is too long" do
      it "raises an error" do
        expect {
          described_class.validate!("lorem ipsum" * 9000, "text-davinci-003")
        }.to raise_error(Langchain::Utils::TokenLimitExceeded)
      end
    end

    context "when the text is not too long" do
      it "does not raise an error" do
        expect {
          described_class.validate!("lorem ipsum" * 100, "gpt-4")
        }.not_to raise_error
      end
    end
  end

  describe "#calculate_max_tokens" do
    context "when the text is too long" do
      it "returns the max tokens" do
        expect(
          described_class.calculate_max_tokens("lorem ipsum" * 9000, "text-davinci-003")
        ).to eq(-40903)
      end
    end
    context "when the text is not too long" do
      it "returns the max tokens" do
        expect(
          described_class.calculate_max_tokens("lorem ipsum" * 100, "gpt-4")
        ).to eq(7892)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Langchain::Utils::TokenLengthValidator do
  describe "#validate_max_tokens!" do
    context "when the text is too long" do
      it "raises an error" do
        expect {
          described_class.validate_max_tokens!("lorem ipsum" * 9000, "text-davinci-003")
        }.to raise_error(Langchain::Utils::TokenLimitExceeded, "This model's maximum context length is 4097 tokens, but the given text is 45000 tokens long.")
      end
    end

    context "when the text is not too long" do
      it "does not raise an error" do
        expect {
          described_class.validate_max_tokens!("lorem ipsum" * 100, "gpt-4")
        }.not_to raise_error
      end
    end
  end
end

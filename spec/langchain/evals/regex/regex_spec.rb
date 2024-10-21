RSpec.describe Langchain::Evals::Regex::Regex do
  subject { described_class.new(regex: /needle/) }

  let(:output) { "This is a **needle** in a haystack" }

  describe "#score" do
    it "returns the Regex score" do
      expect(subject.score(output: output)).to eq(1)
    end
  end
end

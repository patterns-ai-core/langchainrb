RSpec.describe Langchain::Evals::Regex::Regex do
  describe "#score with one attribute" do
    subject { described_class.new(regex: /needle/, attributes: [:answer]) }

    let(:output) { "This is a **needle** in a haystack" }

    it "returns the Regex score" do
      expect(subject.score(answer: output)).to eq(1)

      expect(subject.score(answer: "foobar")).to eq(0)
    end
  end

  describe "#score with multiple attributes" do
    subject { described_class.new(regex: /needle/, attributes: %i[question answer]) }

    let(:question) { "Where is the **needle** in the haystack?" }
    let(:output) { "This is a **needle** in a haystack" }

    it "returns the Regex score" do
      expect(subject.score(question: question, answer: output)).to eq(1)

      expect(subject.score(question: question, answer: "foobar")).to eq(1)

      expect(subject.score(question: "foobar", answer: "foobar")).to eq(0)
    end
  end

  describe "#score with variable interpolation in regex" do
    subject { described_class.new(regex: /%{expected_answer}/, attributes: %i[question answer]) }
    let(:output) { "This is a **needle** in a haystack" }

    it "returns the Regex score" do
      expect(subject.score(answer: output, expected_answer: "needle")).to eq(1)

      expect(subject.score(answer: output, expected_answer: "foobar")).to eq(0)
    end
  end
end
